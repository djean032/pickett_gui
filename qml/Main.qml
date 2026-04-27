import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 1024
    height: 768
    title: qsTr("Pickett Spectral Viewer")

    property int currentPage: 0

    StackLayout {
        anchors.fill: parent
        currentIndex: root.currentPage

        WelcomePage {
            onNavigateToViewer: root.currentPage = 1
        }

        ViewerPage {
            id: viewerPage
            dataModel: spectrumData
            onBack: root.currentPage = 0
        }
    }
}
