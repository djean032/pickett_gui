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

    StackView {
        id: stack
        anchors.fill: parent

        initialItem: WelcomePage {
            onNavigateToViewer: {
                stack.push(viewerPageComponent)
            }
        }
    }

    Component {
        id: viewerPageComponent
        ViewerPage {
            dataModel: spectrumData
        }
    }
}
