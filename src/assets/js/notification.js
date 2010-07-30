/**
 * This class provides access to notifications on the device.
 */
function Notification() {};

/**
 * Open a native alert dialog, with a customizable title and button text.
 * @param {String} message Message to print in the body of the alert
 * @param {String} [title="Alert"] Title of the alert dialog (default: Alert)
 * @param {String} [buttonLabel="OK"] Label of the close button (default: OK)
 */
Notification.prototype.alert = function(message, title, buttonLabel) {
    alert(message); // Default is to use a browser alert; FIXME this will use "index.html" as the title though
};

/**
 * Start spinning the activity indicator on the statusbar
 */
Notification.prototype.activityStart = function() {};

/**
 * Stop spinning the activity indicator on the statusbar, if it's currently spinning
 */
Notification.prototype.activityStop = function() {};

/**
 * Causes the device to blink a status LED.
 * @param {Integer} count The number of blinks.
 * @param {String} colour The colour of the light.
 */
Notification.prototype.blink = function(count, colour) {};

Notification.prototype.vibrate = function(mills) {
    DroidGap.vibrate(mills);
};

/**
 * On the Android, we don't beep, we notify you with your notification! 
 */
Notification.prototype.beep = function(count, volume) {
     DroidGap.beep(count);
};

// TODO: of course on Blackberry and Android there notifications in the UI as well
PhoneGap.addConstructor(function() {
    if (typeof navigator.notification == "undefined") navigator.notification = new Notification();
});
