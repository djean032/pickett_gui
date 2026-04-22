import QtQuick
import QtQuick.Controls
import Pickett 1.0

Rectangle {
    id: root
    property var spectrumData

    color: "white"
    border.color: "black"
    border.width: 1

    SpectrumPlotItem {
        anchors.fill: parent
        anchors.margins: 2
        data: root.spectrumData
    }
}
