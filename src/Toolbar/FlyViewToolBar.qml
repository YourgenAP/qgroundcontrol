import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

Item {
    required property var guidedValueSlider

    id:     control
    width:  parent.width
    height: ScreenTools.toolbarHeight

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost:         _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor:         qgcPal.brandingPurple
    property real   _leftRightMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property var    _guidedController:          globals.guidedControllerFlyView

    property bool   setFocus:                   true
    property string comboBoxGroupName:          "Flight Testing"
    property bool   vehicleParamsReady:     _activeVehicle ? _activeVehicle.parameterManager.parametersReady : false

    property int    parameterFactRole:          Qt.UserRole + 1
    property bool   parameterGroupFound:        false
    property var    groupFacts:                 []
    property var    groupFactNames:             []
    property var    selectedFact:               (_flightTestParameter.currentIndex >= 0 && _flightTestParameter.currentIndex < groupFacts.length)
                                                ? groupFacts[_flightTestParameter.currentIndex]
                                                : null

    onVehicleParamsReadyChanged:            reloadParameterController()
    onSelectedFactChanged:                  refreshValueField()
    Component.onCompleted:                  reloadParameterController()

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {_root.reloadParameterController()}
    }

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    function reloadParameterController() {
        var vehicle = QGroundControl.multiVehicleManager.activeVehicle
        var ready   = vehicle ? vehicle.parameterManager.parametersReady : false
        paramControllerLoader.active = false
        paramControllerLoader.active = ready
    }

    function selectParameterGroup(ctrl, groupName) {
        if (ctrl && ctrl.categories) {
            for (var catId = 0; catId < ctrl.categories.count; catId++) {
                var category = ctrl.categories.get(catId)
                for (var groupId = 0; groupId < category.groups.count; groupId++) {
                    var group = category.groups.get(groupId)
                    if (group.name === groupName) {
                        ctrl.currentCategory = category
                        ctrl.currentGroup    = group
                        return true
                    }
                }
            }
        }
        return false
    }

    function factAtRow(model, row) {
        var idx     = model.index(row, 0)
        var fact    = model.data(idx, parameterFactRole)
        if (fact && fact.name !== undefined) {
            return fact
        }
        return null
    }

    function rebuildParameterList() {
        var ctrl        = paramControllerLoader.item
        var prevName    = selectedFact ? selectedFact.name : ""
        var facts       = []
        var names       = []

        if (ctrl && parameterGroupFound && ctrl.parameters) {
            var model = ctrl.parameters
            for (var row = 0; row < model.rowCount; row++){
                var fact = factAtRow(model, row)
                if (fact) {
                    facts.push(fact)
                    names.push(fact.name)
                }
            }
        }

        groupFacts      = facts
        groupFactNames  = names
        _flightTestParameter.currentIndex = 0
    }

    function refreshValueField() {
        _parameterValue.text = selectedFact ? selectedFact.valueString : ""
    }

    Loader {
        id:         paramControllerLoader
        active:     false

        sourceComponent: Component {
            ParameterEditorController {}
        }

        onLoaded: {
            _root.parameterGroupFound = _root.selectParameterGroup(item, _root.comboBoxGroupName)
            _root.rebuildParameterList()
        }

        onItemChanged: {
            if (!item) {
                _root.parameterGroupFound = false
                _root.rebuildParameterList()
            }
        }
    }

    Connections {
        target:                 paramControllerLoader.item
        ignoreUnknownSignals:   true
        function onParametersChanged() {_root.rebuildParameterList()}
    }
    Connections {
        target:                     paramControllerLoader.item ? paramControllerLoader.item.parameters : null
        ignoreUnknownSignals:       true
        function onModelReset()         {Qt.callLater(_root.rebuildParameterList())}
        function onRowCountChanged()    {Qt.callLater(_root.rebuildParameterList())}
        function onLayoutChanged()      {Qt.callLater(_root.rebuildParameterList())}
    }

    Connections {
        target:                 control.selectedFact
        ignoreUnknownSignals:   true
        function onValueChanged() {
            if(!_parameterValue.activeFocus) {
                _root.refreshValueField()
            }
        }
    }

    QGCPalette { id: qgcPal }

    QGCFlickable {
        anchors.fill:       parent
        contentWidth:       toolBarLayout.width
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id:         toolBarLayout
            height:     parent.height
            spacing:    0

            Item {
                id:     leftPanel
                width:  leftPanelLayout.implicitWidth
                height: parent.height

                // Gradient background behind Q button and main status indicator
                Rectangle {
                    id:         gradientBackground
                    height:     parent.height
                    width:      mainStatusLayout.width
                    opacity:    qgcPal.windowTransparent.a

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: _mainStatusBGColor }
                        //GradientStop { position: qgcButton.x + qgcButton.width; color: _mainStatusBGColor }
                        GradientStop { position: 1; color: qgcPal.window }
                    }
                }

                // Standard toolbar background to the right of the gradient
                Rectangle {
                    anchors.left:   gradientBackground.right
                    anchors.right:  parent.right
                    height:         parent.height
                    color:          qgcPal.windowTransparent
                }

                RowLayout {
                    id:         leftPanelLayout
                    height:     parent.height
                    spacing:    ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        id:         mainStatusLayout
                        height:     parent.height
                        spacing:    0

                        QGCToolBarButton {
                            id:                 qgcButton
                            objectName:         "toolbar_qgcLogo"
                            Layout.fillHeight:  true
                            icon.source:        "/res/QGCLogoFull.svg"
                            logo:               true
                            onClicked:          mainWindow.showToolSelectDialog()
                        }

                        MainStatusIndicator {
                            id:                 mainStatusIndicator
                            objectName:         "toolbar_mainStatusIndicator"
                            Layout.fillHeight:  true
                        }
                    }

                    QGCButton {
                        id:         disconnectButton
                        text:       qsTr("Disconnect")
                        onClicked:  _activeVehicle.closeVehicle()
                        visible:    _activeVehicle && _communicationLost
                    }

                    QGCButton {
                        id:                 pilotMarkerButton
                        text:               qsTr("Pilot Marker")

                        property var markerFact: _activeVehicle && _activeVehicle.parameterManager &&
                                                 _activeVehicle.parameterManager.parametersReady &&
                                                 _active.parameterManager.parameterExists(-1, "PILOT_MARKER") ?
                                                    _activeVehicle.parameterManager.getParameter(-1, "PILOT_MARKER") : null

                        backgroundColor:    markerFact && markerFact.rawValue === 1 ? "green" : "red"
                        visible:            _activeVehicle && !_communicationLost

                        onClicked: {
                            if(markerFact) {
                                markerFact.rawValue = (markerFact.rawValue === 0) ? 1 : 0
                            }
                        }
                    }

                    QGCButton {
                        id:                 loggerButton

                        property bool isLogging: false
                        property bool waitingStatus: false
                        property string accumulatedOutput: ""

                        visible:            _activeVehicle && !_communicationLost

                        text: isLogging ? "Stop logger" : "Ensure logger"
                        primary: isLogging

                        MAVLinkConsoleController {
                            id: conController

                            // onTextChanged: (text) => {
                            //     if (loggerButton.waitingStatus) {
                            //         loggerButton.accumulatedOutput += text

                            //         statusTimer.restart()
                            //     }
                            // }
                        }

                        // Timer {
                        //     id: statusTimer
                        //     interval: 300 //ms
                        //     repeat: false
                        //     onTriggered: {
                        //         loggerButton.waitingStatus = false
                        //         mainWindow.showMessageDialog(
                        //             qsTr("Logger status"),
                        //             loggerButton.accumulatedOutput.trim()
                        //         )
                        //         loggerButton.accumulatedOutput = ""
                        //     }
                        // }

                        onClicked: {
                            if (!_activeVehicle) return

                            if (!isLogging) {
                                conController.sendCommand("logger stop")
                                conController.sendCommand("logger start -f")

                                loggerButton.accumulatedOutput = ""
                                loggerButton.waitingStatus = true
                                conController.sendCommand("logger status")

                                isLogging = true
                            }
                            else {
                                conController.sendCommand("logger stop")
                                isLogging = false
                            }
                        }
                    }

                    QGCComboBox {
                        id:                 _flightTestParameter
                        width:              ScreenTools.defaultFontPixelWidth * 15
                        visible:            _activeVehicle && !_communicationLost
                        focus:              setFocus
                        model:              groupFactNames

                        ToolTip.visible:    hovered && selectedFact
                        ToolTip.delay:      300
                        ToolTip.text:       selectedFact ? selectedFact.shortDescription : ""
                    }

                    QGCTextField {
                        id:                     _parameterValue
                        width:                  ScreenTools.defaultFontPixelWidth * 5
                        visible:                _activeVehicle && !_communicationLost
                        //text:                   selectedFact ? selectedFact.value : ""
                    }

                    QGCButton {
                        id:         sendValueButton
                        visible:    _activeVehicle && !_communicationLost
                        text:       qsTr("Send Value")
                        primary:    true

                        onClicked: {
                            if (!selectedFact) {
                                return
                            }
                            var errorString = selectedFact.validate(_parameterValue.text, false)
                            if (errorString !== "") {
                                mainWindow.showMessageDialog(qsTr("Invalid value"), error)
                                _root.refreshValueField()
                                return
                            }

                            selectedFact.value = _parameterValue.text
                            _parameterValue.focus = false
                        }
                    }

                    FlightModeIndicator {
                        objectName:         "toolbar_flightModeIndicator"
                        Layout.fillHeight:  true
                        visible:            _activeVehicle
                    }
                }
            }
            Item {
                id:     centerPanel
                // center panel takes up all remaining space in toolbar between left and right panels
                width:  Math.max(guidedActionConfirm.visible ? guidedActionConfirm.width : 0, control.width - (leftPanel.width + rightPanel.width))
                height: parent.height

                Rectangle {
                    anchors.fill:   parent
                    color:          qgcPal.windowTransparent
                }

                GuidedActionConfirm {
                    id:                         guidedActionConfirm
                    height:                     parent.height
                    anchors.horizontalCenter:   parent.horizontalCenter
                    guidedController:           control._guidedController
                    guidedValueSlider:          control.guidedValueSlider
                    messageDisplay:             guidedActionMessageDisplay
                }
            }

            Item {
                id:     rightPanel
                width:  flyViewIndicators.width
                height: parent.height

                Rectangle {
                    anchors.fill:   parent
                    color:          qgcPal.windowTransparent
                }

                FlyViewToolBarIndicators {
                    id:     flyViewIndicators
                    height: parent.height
                }
            }
        }
    }

    // The guided action message display is outside of the GuidedActionConfirm control so that it doesn't end up as
    // part of the Flickable
    Rectangle {
        id:                         guidedActionMessageDisplay
        anchors.top:                control.bottom
        anchors.topMargin:          _margins
        x:                          control.mapFromItem(guidedActionConfirm.parent, guidedActionConfirm.x, 0).x + (guidedActionConfirm.width - guidedActionMessageDisplay.width) / 2
        width:                      messageLabel.contentWidth + (_margins * 2)
        height:                     messageLabel.contentHeight + (_margins * 2)
        color:                      qgcPal.windowTransparent
        radius:                     ScreenTools.defaultBorderRadius
        visible:                    guidedActionConfirm.visible

        QGCLabel {
            id:         messageLabel
            x:          _margins
            y:          _margins
            width:      ScreenTools.defaultFontPixelWidth * 30
            wrapMode:   Text.WordWrap
            text:       guidedActionConfirm.message
        }

        PropertyAnimation {
            id:         messageOpacityAnimation
            target:     guidedActionMessageDisplay
            property:   "opacity"
            from:       1
            to:         0
            duration:   500
        }

        Timer {
            id:             messageFadeTimer
            interval:       4000
            onTriggered:    messageOpacityAnimation.start()
        }
    }

    ParameterDownloadProgress {
        anchors.fill: parent
    }
}
