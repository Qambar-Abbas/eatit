# eatit
Eatit is your ultimate kitchen companion, designed specifically for home chefs. 
This intuitive app takes the guesswork out of meal planning, helping you decide what's for breakfast, lunch, and dinner with ease.
Whether you're cooking for yourself, your family, or hosting a dinner party, Menu Maestro ensures every meal is a masterpiece.

## 📸 App Screenshots

<table>
  <tr>
    <td><img src="https://github.com/Qambar-Abbas/eatit/blob/10923bdcf18c726e264a42b63af69e907ff5faf9/ScreenShots/Screenshot%202025-05-19%20at%205.32.36%E2%80%AFPM.png?raw=true" width="250"/></td>
    <td><img src="https://github.com/Qambar-Abbas/eatit/blob/10923bdcf18c726e264a42b63af69e907ff5faf9/ScreenShots/Screenshot%202025-05-19%20at%205.33.26%E2%80%AFPM.png?raw=true" width="250"/></td>
    <td><img src="https://github.com/Qambar-Abbas/eatit/blob/10923bdcf18c726e264a42b63af69e907ff5faf9/ScreenShots/Screenshot%202025-05-19%20at%205.33.36%E2%80%AFPM.png?raw=true" width="250"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/Qambar-Abbas/eatit/blob/10923bdcf18c726e264a42b63af69e907ff5faf9/ScreenShots/Screenshot%202025-05-19%20at%205.34.23%E2%80%AFPM.png?raw=true" width="250"/></td>
    <td><img src="https://github.com/Qambar-Abbas/eatit/blob/10923bdcf18c726e264a42b63af69e907ff5faf9/ScreenShots/Screenshot%202025-05-19%20at%205.34.54%E2%80%AFPM.png?raw=true" width="250"/></td>
    <td></td>
  </tr>
</table>





Changelog:

[v1.9.2]



[v1.9.1]



[v1.9.0]


[v1.8.9]
remove member integrated,
assignment of cook integrated,
moved reiverpod folder,
family code now only display own family's code,



[v1.8.8]
signin fixed,
riverpod introduced,

[v1.8.7]
changes made:
Split sign-in logic into modular helper functions,
Added dedicated error handling for Firebase and general exceptions,
Separated UI logic from business logic,
Used descriptive method and variable names,
Improved code readability and maintainability,
Centralized loading state and snackbar handling,
Moved navigation logic into a dedicated method,
Added comments for clarity and future reference,

changes to be done:
make the drawer translucent,

bugs:
isDeleted user should'nt be able to use app,
delete account method should remove user from all families, mark the cook as null,

[v1.8.6]
Show select family at food search and chat room,
fix profile photo,
Seprate admin's family,

family list is retained in the users collection after removing member. done


[v1.8.5]
Flutter upgrade, Done
Show cook in member list, Done
Remove cook tag function, Done
Show cook in family members list, Done
Delete account funtion also removes admin family, Done
Remove member function, Done


[v1.8.4]
cook assignment working,
chat screen working,
chats added to firstore,
families in list,
members in list,


[v1.8.3]
Icons Added: Drawer,
Family List Working,


[v1.8.2]
code refactor,
services introduced,
models introduced,
unique family code brought back,
profile screen under construction,


[v1.8.1]
user store locally,


[v1.8.1]
web app login integrated,
added client id in index.html,
removed proifle photo and name from profile screen,
moved to customDrawer,


[v1.8.0]
refactored major code,
families in darwer,
create family works,
join family works,
add member not test,


[v1.7.9]
App Verison on singin screen as well
userService deleted
familyService deleted
appServie added


[v1.7.8]
Chat scoket implimented with firestore
Delete member function reintroduced with firestore connection
Drawer moved to right


[v1.7.7]
Family List created
Tags Introduced
Delete member function removed temporarily


[v1.7.6]
ProfileScreen.dart: Updated to include photo URLs and handle null values.
SignInScreen.dart: Updated to ensure photo URLs are handled and family documents are created correctly.


[v1.7.5]
Updated _createAccount Method:
Before: The _createAccount method did not accept BuildContext as a parameter, leading to issues accessing context within it.
After: Modified the _createAccount method to include BuildContext as a parameter. This allows for displaying SnackBars or other UI elements based on the result of the Firestore query.
Added Email Existence Check:

Before: There was no check to prevent creating multiple accounts with the same email.
After: Implemented a check to query Firestore for existing documents with the same email before creating a new account. If an account with the same email already exists, a SnackBar is shown to inform the user.
Passed BuildContext to _createAccount:

Before: The context parameter was not available in the _createAccount method, which could lead to issues with UI updates.
After: Passed BuildContext from _showAccountSetupDialog when calling _createAccount, ensuring that UI elements like SnackBars can be used correctly.
Updated Navigator.pushReplacement Calls:

Before: Navigation was handled directly in the dialog actions.
After: Ensured navigation is handled appropriately after creating or setting up the account, ensuring the user is directed to the correct screen based on the account type.
General Updates
Error Handling and User Feedback:

Improved error handling and user feedback by using ScaffoldMessenger.of(context).showSnackBar to display relevant messages in case of sign-in or account creation failures.
Added error handling for null user scenarios and improved messaging for sign-in failures.
Updated Firestore Document Paths:

Corrected the Firestore document paths to align with the intended structure, ensuring proper user and family document updates.


[v1.7.3]
Firestore user/admin subtype added.
admin_dialog file deleted


[v1.7.2]
Added App Info Section: A new section was added to the CustomDrawer to display app information.
Dependencies: Added package_info_plus package to fetch app details.
App Info Displayed:
App Version
Build Number
Package Name
UI Enhancements:
Added a Divider to separate the app info section from the rest of the drawer content.
Refactored Drawer:
Extracted drawer functionality into a separate CustomDrawer widget.
Passed contactsFuture, onAddFamilyMember, onFilterContacts, searchQuery, and onSignOut as parameters to CustomDrawer.
Updated the ProfileScreen to use CustomDrawer for improved modularity and code organization.
](https://github.com/Qambar-Abbas/eatit/tree/10923bdcf18c726e264a42b63af69e907ff5faf9/ScreenShots)
