# Googiri

[On Cydia](http://apt.thebigboss.org/onepackage.php?bundleid=com.mattcmultimedia.googiri&db=)

Googiri is a powerful middleware broker for Google's voice search feature. It allows you to handle searches with Siri, Google, or your own webserver.

The best use case is in home automation; use Googiri to send Google-quality speech-to-text to your automation setup straight from the jailbroken iDevice.

## Features

- Use Siri's first party integration features with Google's speech-to-text
    + i.e. speak to Google, get results from Siri
    + use Google to transcribe your message and Siri to create the reminders
- Set a default handler (Siri, Google, or a Webserver) to handle normal queries
    + i.e. who should handle "how tall is the empire state building?"
    + default: `Google`
- When you want to explicitly handle a query with a certain handler, specify it before the query.
    + i.e. "Jarvis, turn off my thermostat" rather than simply "turn off my thermostat"
- When using your own webserver, you may return JSON to trigger actions on the iDevice, including access to every installed Activator listener.
    + Success or Error responses can also be displayed on the device from the webserver


## Docs

Response JSON (check out the example server) can contain the following fields:


| Property | Type | Description | Default |
| ----- | ------ | ----- | ----- |
| title | **string** | Title of the alert view | None |
| text | **string** | Text of the alert view | None |
| style | **string** | style of the alert view - "success", "error", "notice", "warning", "info" | "success" |
| activator  | **string** | the unique name of an activator listener to trigger on the device (see a list of installed listeners by running "activator listeners" via ssh on your device) | None |
| doneText | **string** | alert view done button text | "Done!" |
| duration | **float** | duration alert view stays on screen. 0.0f is forever | 0.0f |
| reListen | **bool** | tell Googiri to listen for more commands after this query | false |
| context | **string** | give Googiri a context string that will allow you to maintain a context on your server for subsequen requests. It will be sent with every request in the query params | "default"