import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Pickett 1.0

Page {
    id: page
    property var dataModel

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            spacing: 10

            Button {
                text: qsTr("← Back")
                onClicked: {
                    page.StackView.view.pop()
                }
            }

            Button {
                text: qsTr("Load Spectrum")
                onClicked: fileDialog.open()
            }

            Label {
                text: dataModel ? dataModel.fileName : qsTr("No file loaded")
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        SpectrumPlot {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spectrumData: dataModel
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Load Spectrum")
        nameFilters: ["All files (*.*)"]
        onAccepted: {
            console.log("FileDialog accepted, selectedFile:", selectedFile)
            if (dataModel) {
                console.log("Calling loadFile with:", selectedFile.toString())
                dataModel.loadFile(selectedFile)
            } else {
                console.log("ERROR: dataModel is null")
            }
        }
    }
}
