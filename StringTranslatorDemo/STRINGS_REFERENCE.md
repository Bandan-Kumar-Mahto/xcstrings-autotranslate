# Strings Reference

These are sample localization string formats kept here for future reference.

## Basic Key-Value Format

```
"Welcome to the app!" = "Welcome to the app!";
"Log In" = "Log In";
"Create Account" = "Create Account";
"Forgot Password?" = "Forgot Password?";
"Edit Profile" = "Edit Profile";
"Settings" = "Settings";
"Are you sure you want to log out?" = "Are you sure you want to log out?";
"Something went wrong. Please try again." = "Something went wrong. Please try again.";
"Retry" = "Retry";
"empty_state_message" = "No data available.";
"Search here..." = "Search here...";
"Notifications Enabled" = "Notifications Enabled";
"Save Changes" = "Save Changes";
"Cancel" = "Cancel";
"Delete Item" = "Delete Item";
"Your changes have been saved successfully." = "Your changes have been saved successfully.";
"Loading..." = "Loading...";
"Hello, %@!" = "Hello, %@!";
"items_count" = "%d items available";
"Last updated on %@" = "Last updated on %@";
```

## Advanced Format Examples (Named Positional Arguments)

```
/* Simple localized strings */
"welcome_message" = "Welcome to the app!";
"login_button_title" = "Log In";
"signup_button_title" = "Create Account";

/* String with named positional argument */
"welcome_user" = "Hello, %1$(userName)@!";

/* Multiple named arguments */
"greeting_full_name" = "Hello, %1$(firstName)@ %2$(lastName)@!";

/* Integer formatting */
"items_count" = "%1$(count)lld items available";

/* Float formatting */
"temperature_reading" = "Current temperature is %1$(temp).1f°C";

/* Percentage formatting */
"upload_progress" = "Uploading... %1$(progress).2f%% complete";

/* Date placeholder */
"last_updated" = "Last updated on %1$(date)@";

/* Currency formatting */
"purchase_total" = "Total amount: $%1$(amount).2f";

/* Multiple mixed placeholders */
"trip_summary" = "%1$(user)@ booked %2$(count)lld tickets for $%3$(price).2f";

/* Escaped newline */
"multiline_greeting" = "Hello, %@!\nWelcome back to the app.";

/* Escaped quotes */
"quote_message" = "\"Success\" is built one step at a time.";

/* Tab escape */
"tabbed_text" = "Name:\t%@";

/* Boolean-like status messaging */
"feature_enabled" = "Feature enabled: %@";

/* Retry counter */
"retry_action" = "Retry Count %1$(count)lld";

/* File size formatting */
"download_size" = "Downloaded %1$(size).2f MB";

/* Time formatting */
"remaining_time" = "%1$(minutes)lld minutes remaining";

/* Achievement / dynamic title */
"achievement_unlocked" = "Achievement unlocked: %1$(title)@";

/* Email placeholder */
"email_sent" = "Verification email sent to %1$(email)@";

/* Complex sentence */
"order_confirmation" = "Order #%1$(orderId)lld for %2$(customerName)@ has been confirmed.";
```
