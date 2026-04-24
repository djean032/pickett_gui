import QtQuick
import QtQuick.Controls
import Pickett 1.0

FocusScope {
    id: root
    property var spectrumData

    Rectangle {
        anchors.fill: parent
        color: "blue"
        border.color: "gray"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // Top readout bar
            Rectangle {
                width: parent.width
                height: 22
                color: "gray"
                visible: plotItem.hasData

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    text: "Current Frequency: " + plotItem.cursorX.toFixed(2) + " MHz"
                    color: "white"
                    font.pixelSize: 14
                }
            }

            // Plot area
            Rectangle {
                width: parent.width
                height: parent.height - 22
                color: "blue"
                clip: true

                SpectrumPlotItem {
                    id: plotItem
                    anchors.fill: parent
                    anchors.margins: 2
                    anchors.bottomMargin: 36
                    data: root.spectrumData
                }

                // Cursor + axis overlay (hidden until data loaded)
                Item {
                    anchors.fill: plotItem
                    visible: plotItem.hasData

                    // Cursor line (follows cursorX)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: "yellow"
                        z: 10
                        x: (plotItem.cursorX - plotItem.viewXMin) / (plotItem.viewXMax - plotItem.viewXMin) * plotItem.width
                    }

                    // X-axis line
                    Rectangle {
                        id: xAxisLine
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        color: "white"
                    }

                    // Major ticks and labels (grow downward from x-axis)
                    Repeater {
                        model: plotItem.xTickPositions
                        Item {
                            x: (modelData - plotItem.viewXMin) / (plotItem.viewXMax - plotItem.viewXMin) * plotItem.width - width / 2
                            anchors.top: xAxisLine.bottom
                            height: 32
                            width: 2

                            Rectangle {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 2
                                height: 12
                                color: "white"
                            }

                            Text {
                                anchors.top: parent.top
                                anchors.topMargin: 14
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.round(modelData).toString()
                                color: "white"
                                font.pixelSize: 14
                            }
                        }
                    }

                    // Minor ticks (grow downward from x-axis)
                    Repeater {
                        model: plotItem.xMinorPositions
                        Rectangle {
                            x: (modelData - plotItem.viewXMin) / (plotItem.viewXMax - plotItem.viewXMin) * plotItem.width - width / 2
                            anchors.top: xAxisLine.bottom
                            width: 1
                            height: 6
                            color: "white"
                        }
                    }
                }
            }
        }
    }

    focus: true

    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
    }

    Timer {
        interval: 0
        running: parent.visible
        onTriggered: root.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        var isShift = event.modifiers & Qt.ShiftModifier;
        var panStep = isShift ? 0.20 : 0.01;
        var zoomStep = isShift ? 0.20 : 0.10;
        var cursorStep = isShift ? 8 : 1;

        switch (event.key) {
        case Qt.Key_A:
            plotItem.panX(-panStep);
            event.accepted = true;
            break;
        case Qt.Key_S:
            plotItem.panX(panStep);
            event.accepted = true;
            break;
        case Qt.Key_E:
            plotItem.zoomX(1.0 + zoomStep);
            event.accepted = true;
            break;
        case Qt.Key_Q:
            plotItem.zoomX(1.0 - zoomStep);
            event.accepted = true;
            break;
        case Qt.Key_Z:
            plotItem.zoomY(1.0 + zoomStep);
            event.accepted = true;
            break;
        case Qt.Key_W:
            plotItem.zoomY(1.0 - zoomStep);
            event.accepted = true;
            break;
        case Qt.Key_2:
            plotItem.panY(-panStep);
            event.accepted = true;
            break;
        case Qt.Key_3:
            plotItem.panY(panStep);
            event.accepted = true;
            break;
        case Qt.Key_K:
            plotItem.moveCursor(-cursorStep);
            event.accepted = true;
            break;
        case Qt.Key_L:
            plotItem.moveCursor(cursorStep);
            event.accepted = true;
            break;
        case Qt.Key_0:
            plotItem.resetView();
            event.accepted = true;
            break;
        }
    }
}
