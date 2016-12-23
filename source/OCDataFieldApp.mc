using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class OCDataFieldApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }
    
    function onStart(state) {
    }

    function onStop(state) {
    }
    
    function getInitialView()
    {
        return [new OCDataFieldView()];
    }
    
    function onSettingsChanged()
    {
        Ui.requestUpdate();
    }
}