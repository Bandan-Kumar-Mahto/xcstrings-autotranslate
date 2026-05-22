import contextlib
import json
import re
import time
import subprocess
import sys
import argparse
from datetime import date
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# ======================================================
# ARGUMENT PARSING
# ======================================================

parser = argparse.ArgumentParser()
parser.add_argument('--resource-dir', required=False, default=None)
parser.add_argument('--no-interactive', action='store_true')
args = parser.parse_args()

# ======================================================
# AUTO-INSTALL DEPENDENCIES
# ======================================================

def install_missing_packages():
    """Automatically install required packages if not found"""
    required_packages = {
        'deep_translator': 'deep-translator',
        'tqdm': 'tqdm'
    }
    
    missing_packages = []
    
    # Check which packages are missing
    for import_name, package_name in required_packages.items():
        try:
            __import__(import_name)
            print(f"✓ {package_name} already installed")
        except ImportError:
            print(f"⚠ {package_name} not found, will install...")
            missing_packages.append(package_name)
    
    # Install missing packages
    if missing_packages:
        print(f"\nInstalling {len(missing_packages)} package(s)...")
        try:
            for package in missing_packages:
                subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            print("✓ All packages installed successfully\n")
        except subprocess.CalledProcessError as e:
            print(f"✗ Error installing packages: {e}")
            print("Please manually run: pip install deep-translator tqdm")
            sys.exit(1)

# Install dependencies before importing
install_missing_packages()

# Now import after dependencies are guaranteed to exist
from deep_translator import GoogleTranslator
from tqdm import tqdm

# ======================================================
# CONFIG
# ======================================================

# Number of parallel translation threads
MAX_THREADS = 5

# Add extra languages manually if needed
EXTRA_LANGUAGES = []

# ======================================================
# PLACEHOLDER PROTECTION
# ======================================================

# Protect placeholders like:
# %@  %d  %f  %@ etc.
PLACEHOLDER_PATTERN = r"%[@dfsu]|%\d+\$[@dfsu]"

def protect_placeholders(text):
    placeholders = re.findall(PLACEHOLDER_PATTERN, text)

    protected = text

    for i, placeholder in enumerate(placeholders):
        token = f"__PLACEHOLDER_{i}__"
        protected = protected.replace(placeholder, token, 1)

    return protected, placeholders


def restore_placeholders(text, placeholders):
    restored = text

    for i, placeholder in enumerate(placeholders):
        token = f"__PLACEHOLDER_{i}__"
        restored = restored.replace(token, placeholder)

    return restored

# ======================================================
# FALLBACK: GENERATE XCSTRINGS FROM .lproj FILES
# ======================================================

BASE_DIR = Path(args.resource_dir).resolve() if args.resource_dir else Path(__file__).parent.resolve()
XCSTRINGS_FILE = str(BASE_DIR / "Localizable.xcstrings")
OUTPUT_FILE = str(BASE_DIR / "Localizable_translated.xcstrings")

STRINGS_PATTERN = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
HEADER = (
    "/* \n"
    "  Localizable.strings\n"
    "  Produced by a script engineered by the Developer.\n"
    f"  {date.today().strftime('%d/%m/%y')}\n"
    "*/\n\n"
)


def read_strings_file(filepath):
    """Read a .strings file trying utf-8 and utf-16 encodings."""
    for encoding in ['utf-8', 'utf-16']:
        try:
            with open(filepath, 'r', encoding=encoding) as f:
                return f.read(), encoding
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Could not decode file: {filepath}")


def strip_comments(content):
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    content = re.sub(r'//.*', '', content)
    return content


def parse_strings_file(filepath):
    content, encoding = read_strings_file(filepath)
    clean_content = strip_comments(content)
    pairs = STRINGS_PATTERN.findall(clean_content)
    return pairs, encoding


def write_strings_file(filepath, pairs, encoding):
    with open(filepath, 'w', encoding=encoding) as f:
        f.write(HEADER)
        for key, val in pairs:
            f.write(f'"{key}" = "{val}";\n')


def generate_xcstrings_from_lproj():
    """Generate Localizable.xcstrings from available .lproj Localizable.strings."""
    print(f"Localizable.xcstrings not found. Generating from .lproj files...")

    lproj_dirs = [
        d for d in BASE_DIR.iterdir()
        if d.is_dir() and d.suffix == '.lproj'
    ]

    if not lproj_dirs:
        print("No .lproj localization directories found.")
        return False

    translation_map = {}
    all_keys = []
    seen_global = set()

    for lproj in sorted(lproj_dirs):
        locale = lproj.name[:-6] if lproj.name.endswith('.lproj') else lproj.name
        strings_file = lproj / 'Localizable.strings'

        if not strings_file.exists():
            continue

        pairs, encoding = parse_strings_file(strings_file)
        cleaned_pairs = []
        seen_local = set()

        for key, val in pairs:
            if key in seen_local:
                continue
            seen_local.add(key)
            cleaned_pairs.append((key, val))

            if key not in seen_global:
                seen_global.add(key)
                all_keys.append(key)

        write_strings_file(strings_file, cleaned_pairs, encoding)
        translation_map[locale] = {key: val for key, val in cleaned_pairs}
        print(f"✓ Cleaned {strings_file.relative_to(BASE_DIR)}")

    if not all_keys:
        print("No localization keys were found in .lproj files.")
        return False

    xcstrings_data = {
        'sourceLanguage': 'en',
        'strings': {},
        'version': '1.2'
    }

    for key in sorted(all_keys):
        localizations = {}

        for locale, kv in translation_map.items():
            if key in kv:
                localizations[locale] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': kv[key]
                    }
                }

        if 'en' not in localizations:
            localizations['en'] = {
                'stringUnit': {
                    'state': 'translated',
                    'value': key
                }
            }

        xcstrings_data['strings'][key] = {
            'extractionState': 'manual',
            'localizations': localizations
        }

    with open(XCSTRINGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(xcstrings_data, f, ensure_ascii=False, indent=2)

    print(f"✓ Generated {XCSTRINGS_FILE} from .lproj files")
    return True

# ======================================================
# LOAD XCSTRINGS FILE
# ======================================================

path = Path(XCSTRINGS_FILE)

if not path.exists():
    if not generate_xcstrings_from_lproj():
        print(f"ERROR: File not found -> {XCSTRINGS_FILE}")
        sys.exit(1)
    path = Path(XCSTRINGS_FILE)

print("\nLoading XCStrings file...")

try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    print("XCStrings file loaded successfully")

except Exception as e:
    print(f"Failed to load file: {e}")
    exit()

# ======================================================
# VALIDATE STRUCTURE
# ======================================================

print("\nTop level keys:")
print(data.keys())

if "strings" not in data:
    print("\nERROR: No 'strings' key found.")
    exit()

strings = data["strings"]

print(f"\nTotal string entries: {len(strings)}")

source_language = data.get("sourceLanguage", "en")

print(f"Source language: {source_language}")

# ======================================================
# ENSURE EXTRACTION STATE
# ======================================================

for key, item in strings.items():
    if "extractionState" not in item:
        item["extractionState"] = "manual"

# ======================================================
# DETECT LANGUAGES
# ======================================================

languages = set(EXTRA_LANGUAGES)

for key, item in strings.items():

    localizations = item.get("localizations", {})

    for lang in localizations.keys():
        languages.add(lang)

# Remove source language
languages.discard(source_language)

languages = sorted(list(languages))

print("\nDetected Languages:")

for lang in languages:
    print(f"- {lang}")

print("====================================")

# ======================================================
# BUILD TRANSLATION TASKS
# ======================================================

translation_tasks = []

for key, item in strings.items():

    localizations = item.setdefault("localizations", {})

    source_text = key

    # Prefer actual source language value
    if source_language in localizations:

        source_unit = (
            localizations[source_language]
            .get("stringUnit", {})
        )

        source_text = source_unit.get("value", key)

    # Skip empty strings
    if not source_text or source_text.strip() == "":
        continue

    # Skip emoji-only strings
    emoji_only = all(
        not ch.isalnum()
        and not ch.isspace()
        for ch in source_text
    )

    if emoji_only:
        continue

    for lang in languages:

        lang_data = localizations.get(lang)

        needs_translation = False

        if lang_data is None:
            needs_translation = True

        else:
            unit = lang_data.get("stringUnit", {})

            value = unit.get("value", "")
            state = unit.get("state", "")

            # Check if this value is the same as the value in any other language
            same_as_other_lang = False
            if value and value.strip() != "":
                for other_lang, other_lang_data in localizations.items():
                    if other_lang == lang:
                        continue
                    other_unit = other_lang_data.get("stringUnit", {})
                    other_value = other_unit.get("value", "")
                    if other_value and value == other_value:
                        same_as_other_lang = True
                        break

            if (
                value is None
                or value.strip() == ""
                or value == source_text
                or state != "translated"
                or same_as_other_lang
            ):
                needs_translation = True

        if needs_translation:

            translation_tasks.append({
                "key": key,
                "source_text": source_text,
                "lang": lang
            })

print(f"\nTasks prepared: {len(translation_tasks)}")

if len(translation_tasks) == 0:
    print("\nNo missing translations were found.")
    exit()

print("\nStarting translation process...")
print("====================================")

# ======================================================
# TRANSLATION FUNCTION
# ======================================================

def translate_text(text, target_lang, retries=3, delay=1.0):

    if not text or text.strip() == "":
        return text

    for attempt in range(retries):
        try:
            protected_text, placeholders = protect_placeholders(text)

            translated = GoogleTranslator(
                source=source_language,
                target=target_lang
            ).translate(protected_text)

            # Prevent None values
            if translated is None or translated.strip() == "":
                translated = text

            translated = restore_placeholders(
                translated,
                placeholders
            )

            return translated

        except Exception as e:
            if attempt < retries - 1:
                sleep_time = delay * (2 ** attempt)
                time.sleep(sleep_time)
            else:
                print(f"\nTranslation failed [{target_lang}] after {retries} attempts.")
                print(f"Text: {text}")
                print(f"Error: {e}")
                return text

# ======================================================
# PROCESS TASK
# ======================================================

def process_task(task):

    translated = translate_text(
        task["source_text"],
        task["lang"]
    )

    return {
        "key": task["key"],
        "lang": task["lang"],
        "translated": translated,
        "source_text": task["source_text"]
    }

# ======================================================
# MULTITHREADED TRANSLATION
# ======================================================

results = []

start_time = time.time()

with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:

    futures = [
        executor.submit(process_task, task)
        for task in translation_tasks
    ]

    for future in tqdm(
        as_completed(futures),
        total=len(futures),
        desc="Translating",
        unit="string"
    ):

        try:

            results.append(future.result())

        except Exception as e:

            print(f"\nThread failed: {e}")

# ======================================================
# APPLY TRANSLATIONS
# ======================================================

print("\nApplying translations...")

for result in results:

    key = result["key"]
    lang = result["lang"]
    translated = result["translated"]
    src_text = result["source_text"]

    localizations = (
        strings[key]
        .setdefault("localizations", {})
    )

    localizations[lang] = {
        "stringUnit": {
            "state": "translated",
            "value": translated if translated else src_text
        }
    }

# ======================================================
# SAVE FILE
# ======================================================

print("\nSaving translated file...")

try:

    with open(
        OUTPUT_FILE,
        "w",
        encoding="utf-8"
    ) as f:

        json.dump(
            data,
            f,
            ensure_ascii=False,
            indent=2
        )

    print(f"✓ Saved to: {OUTPUT_FILE}")

except Exception as e:
    print(f"\nFailed to save translated file: {e}")
    sys.exit(1)

# ======================================================
# RENAME AND ORGANIZE FILES
# ======================================================

print("\nOrganizing files...")

try:
    original_file = BASE_DIR / "Localizable.xcstrings"
    output_file = BASE_DIR / "Localizable_translated.xcstrings"
    backup_file = BASE_DIR / "Localizable_old.xcstrings"
    final_file = BASE_DIR / "Localizable.xcstrings"
    
    # Step 1: Backup original file
    if original_file.exists():
        if backup_file.exists():
            backup_file.unlink()
            print(f"✓ Removed old backup: {backup_file}")
        
        original_file.rename(backup_file)
        print(f"✓ Backed up original to: {backup_file}")
    
    # Step 2: Rename translated file to main file
    if output_file.exists():
        if final_file.exists():
            final_file.unlink()
        output_file.rename(final_file)
        print(f"✓ Moved translations to: {final_file}")
    
    # Step 3: Delete backup (auto in build, interactive in terminal)
    if args.no_interactive:
        if backup_file.exists():
            backup_file.unlink()
            print(f"✓ Deleted: {backup_file}")
    else:
        print("\n====================================")
        print("Would you like to delete the old backup file?")
        print(f"File: {backup_file}")
        user_input = input("Delete? (yes/no): ").strip().lower()

        if user_input in ['yes', 'y']:
            if backup_file.exists():
                backup_file.unlink()
                print(f"✓ Deleted: {backup_file}")
        else:
            print(f"✓ Kept backup: {backup_file}")
    
    duration = round(time.time() - start_time, 2)

    print("\n====================================")
    print("✓ Translation Pipeline Completed!")
    print("====================================")
    print(f"Main file: {final_file}")
    print(f"Backup file: {backup_file}")
    print(f"Total time: {duration} seconds")
    print("====================================\n")

except Exception as e:
    print(f"\n✗ Error organizing files: {e}")
    sys.exit(1)
