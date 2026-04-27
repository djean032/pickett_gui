import QtQuick
import QtQuick.Controls
import Pickett 1.0

FocusScope {
    id: root
    property var spectrumData
    property var catalogData

    // Shared viewport state for both plots
    ViewportModel {
        id: viewport
        catalogData: root.catalogData
    }

    // Sync viewport bounds when spectrum data loads/changes
    Connections {
        target: root.spectrumData
        function onDataChanged() {
            if (root.spectrumData && root.spectrumData.hasData) {
                viewport.setDataBounds(root.spectrumData.xMin, root.spectrumData.xMax)
                // If this is the only loaded data, reset view to show it fully
                if (!root.catalogData || !root.catalogData.hasData) {
                    viewport.resetView()
                }
            }
        }
    }

    // Sync viewport bounds when catalog data loads/changes
    Connections {
        target: root.catalogData
        function onDataChanged() {
            if (root.catalogData && root.catalogData.hasData) {
                viewport.setDataBounds(root.catalogData.xMin, root.catalogData.xMax)
                // If this is the only loaded data, reset view to show it fully
                if (!root.spectrumData || !root.spectrumData.hasData) {
                    viewport.resetView()
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        border.color: "gray"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // Shared readout bar (100 px)
            Rectangle {
                width: parent.width
                height: (plotItem.hasData || catalogPlotItem.hasData) ? 100 : 0
                color: "gray"
                visible: height > 0

                Text {
                    id: readoutText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    
                    property var lineInfo: {
                        if (!viewport.hasData) return {};
                        var pixel = (viewport.cursorX - viewport.viewXMin) / 
                                   (viewport.viewXMax - viewport.viewXMin) * plotItem.width;
                        return viewport.lineAtPixel(pixel, plotItem.width);
                    }
                    
                    text: {
                        if (!lineInfo.found) {
                            return "Current Frequency: " + viewport.cursorX.toFixed(2) + " MHz";
                        }
                        var prefix = "";
                        if (lineInfo.totalLines > 1) {
                            prefix = "Line " + (lineInfo.lineIndex + 1) + "/" + 
                                     lineInfo.totalLines + " | " + "Current Frequency: " + viewport.cursorX.toFixed(2) + " MHz" + " | ";
                        } else {
                            prefix = "Current Frequency: " + viewport.cursorX.toFixed(2) + " MHz" + " | ";
                        }

                        var upper = "";
                        var lower = "";
                        if (lineInfo.upperLabels && lineInfo.upperQN) {
                            for (var i = 0; i < lineInfo.upperLabels.length; ++i) {
                                if (i > 0) upper += ", ";
                                upper += lineInfo.upperLabels[i] + ": " + lineInfo.upperQN[i];
                            }
                        }
                        if (lineInfo.lowerLabels && lineInfo.lowerQN) {
                            for (var j = 0; j < lineInfo.lowerLabels.length; ++j) {
                                if (j > 0) lower += ", ";
                                lower += lineInfo.lowerLabels[j] + ": " + lineInfo.lowerQN[j];
                            }
                        }
                        return prefix + "Predicted Freq: " + lineInfo.freq.toFixed(4) + " MHz\n" +
                               "Upper: " + upper + "\nLower: " + lower + "\n" +
                               "Int: " + lineInfo.lgint.toFixed(4);
                    }
                    }
                  }

            // Spectrum plot area (full size when it's the only one loaded, half when both are loaded)
            Item {
                width: parent.width
                height: {
                    var totalH = parent.height - ((plotItem.hasData || catalogPlotItem.hasData) ? 100 : 0);
                    if (!plotItem.hasData) return 0;
                    if (catalogPlotItem.hasData) return Math.max(0, totalH / 2);
                    return Math.max(0, totalH);
                }
                visible: height > 0
                clip: true

                SpectrumPlotItem {
                    id: plotItem
                    anchors.fill: parent
                    anchors.margins: 2
                    anchors.bottomMargin: 36
                    data: root.spectrumData
                    viewport: viewport
                }

                // Cursor + axis overlay for spectrum
                Item {
                    anchors.fill: plotItem
                    visible: plotItem.hasData

                    // Cursor line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: "yellow"
                        z: 10
                        x: {
                            var range = viewport.viewXMax - viewport.viewXMin;
                            if (range <= 0 || parent.width <= 0) return 0;
                            return (viewport.cursorX - viewport.viewXMin) / range * parent.width;
                        }
                    }

                    // X-axis line
                    Rectangle {
                        id: xAxisLineSpectrum
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        color: "white"
                    }

                    // Major ticks and labels
                    Repeater {
                        model: viewport.xTickPositions
                        Item {
                            x: {
                                var range = viewport.viewXMax - viewport.viewXMin;
                                if (range <= 0 || parent.width <= 0) return 0;
                                return (modelData - viewport.viewXMin) / range * parent.width - width / 2;
                            }
                            anchors.top: xAxisLineSpectrum.bottom
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

                    // Minor ticks
                    Repeater {
                        model: viewport.xMinorPositions
                        Rectangle {
                            x: {
                                var range = viewport.viewXMax - viewport.viewXMin;
                                if (range <= 0 || parent.width <= 0) return 0;
                                return (modelData - viewport.viewXMin) / range * parent.width - width / 2;
                            }
                            anchors.top: xAxisLineSpectrum.bottom
                            width: 1
                            height: 6
                            color: "white"
                        }
                    }
                }
            }

            // Catalog plot area (full size when it's the only one loaded, half when both are loaded)
            Item {
                width: parent.width
                height: {
                    var totalH = parent.height - ((plotItem.hasData || catalogPlotItem.hasData) ? 100 : 0);
                    if (!catalogPlotItem.hasData) return 0;
                    if (plotItem.hasData) return Math.max(0, totalH / 2);
                    return Math.max(0, totalH);
                }
                visible: height > 0
                clip: true

                CatalogPlotItem {
                    id: catalogPlotItem
                    anchors.fill: parent
                    anchors.margins: 2
                    anchors.bottomMargin: 36
                    catalogData: root.catalogData
                    viewport: viewport
                }

                // Separator line between spectrum and catalog (only when both are present)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "gray"
                    visible: plotItem.hasData && catalogPlotItem.hasData
                }

                // Cursor + axis overlay for catalog
                Item {
                    anchors.fill: catalogPlotItem
                    visible: catalogPlotItem.hasData

                    // Cursor line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: "yellow"
                        z: 10
                        x: {
                            var range = viewport.viewXMax - viewport.viewXMin;
                            if (range <= 0 || parent.width <= 0) return 0;
                            return (viewport.cursorX - viewport.viewXMin) / range * parent.width;
                        }
                    }

                    // X-axis line
                    Rectangle {
                        id: xAxisLineCatalog
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        color: "white"
                    }

                    // Major ticks and labels
                    Repeater {
                        model: viewport.xTickPositions
                        Item {
                            x: {
                                var range = viewport.viewXMax - viewport.viewXMin;
                                if (range <= 0 || parent.width <= 0) return 0;
                                return (modelData - viewport.viewXMin) / range * parent.width - width / 2;
                            }
                            anchors.top: xAxisLineCatalog.bottom
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

                    // Minor ticks
                    Repeater {
                        model: viewport.xMinorPositions
                        Rectangle {
                            x: {
                                var range = viewport.viewXMax - viewport.viewXMin;
                                if (range <= 0 || parent.width <= 0) return 0;
                                return (modelData - viewport.viewXMin) / range * parent.width - width / 2;
                            }
                            anchors.top: xAxisLineCatalog.bottom
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
            viewport.panX(-panStep);
            event.accepted = true;
            break;
        case Qt.Key_S:
            viewport.panX(panStep);
            event.accepted = true;
            break;
        case Qt.Key_E:
            viewport.zoomX(1.0 + zoomStep);
            event.accepted = true;
            break;
        case Qt.Key_Q:
            viewport.zoomX(1.0 - zoomStep);
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
            viewport.moveCursor(-cursorStep, plotItem.width);
            event.accepted = true;
            break;
        case Qt.Key_L:
            viewport.moveCursor(cursorStep, plotItem.width);
            event.accepted = true;
            break;
        case Qt.Key_0:
            viewport.resetView();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            viewport.cycleLineUp();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            viewport.cycleLineDown();
            event.accepted = true;
            break;
        }
    }
}
