import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page
    signal navigateToViewer()

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Label {
            text: qsTr("Welcome to Pickett Spectral Viewer")
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            text: qsTr("Open Viewer")
            Layout.alignment: Qt.AlignHCenter
            onClicked: page.navigateToViewer()
        }
    }
}
