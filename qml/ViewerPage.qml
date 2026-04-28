import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Pickett 1.0

Page {
    id: page
    property var dataModel
    signal back()
    focus: true

    SpectralFileService {
        id: spectralFileService
    }

    onDataModelChanged: {
        if (dataModel) {
            dataModel.fileService = spectralFileService
        }
    }

    Component.onCompleted: {
        if (dataModel) {
            dataModel.fileService = spectralFileService
        }
    }

    CatalogData {
        id: catalogData
        fileService: spectralFileService
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            spacing: 10

            Button {
                text: qsTr("← Back")
                focusPolicy: Qt.NoFocus
                onClicked: page.back()
            }

            Button {
                text: qsTr("Load Spectrum")
                focusPolicy: Qt.NoFocus
                onClicked: spectrumFileDialog.open()
            }

            Button {
                text: qsTr("Load Catalog")
                focusPolicy: Qt.NoFocus
                onClicked: catalogFileDialog.open()
            }

            Label {
                text: dataModel ? dataModel.fileName : qsTr("No file loaded")
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        SpectrumPlot {
            id: spectrumPlot
            Layout.fillWidth: true
            Layout.fillHeight: true
            spectrumData: dataModel
            catalogData: catalogData
        }
    }

    Keys.forwardTo: [spectrumPlot]

    FileDialog {
        id: spectrumFileDialog
        title: qsTr("Load Spectrum")
        nameFilters: ["All files (*.*)"]
        onAccepted: {
            console.log("Spectrum FileDialog accepted, selectedFile:", selectedFile)
            if (dataModel) {
                console.log("Calling loadFile with:", selectedFile.toString())
                dataModel.loadFile(selectedFile)
            } else {
                console.log("ERROR: dataModel is null")
            }
        }
    }

    FileDialog {
        id: catalogFileDialog
        title: qsTr("Load Catalog")
        nameFilters: ["CAT files (*.cat)", "All files (*.*)"]
        onAccepted: {
            console.log("Catalog FileDialog accepted, selectedFile:", selectedFile)
            if (catalogData) {
                console.log("Calling loadFile with:", selectedFile.toString())
                catalogData.loadFile(selectedFile)
            } else {
                console.log("ERROR: catalogData is null")
            }
        }
    }
}
