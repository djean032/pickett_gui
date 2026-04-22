#include "mainwindow.h"
#include "spectrumplotwidget.h"
#include "./src/parsers/spe_parser.h"

#include <iostream>
#include <QStackedWidget>
#include <QWidget>
#include <QVBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QFileDialog>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
  stack = new QStackedWidget;

         // Add pages
  stack->addWidget(createPage1()); // index 0
  stack->addWidget(createPage2()); // index 1

  setCentralWidget(stack);

  setWindowTitle("QStackedWidget in MainWindow");
  resize(400, 300);
}

// --- Page 1 ---
QWidget* MainWindow::createPage1() {
  QWidget* page = new QWidget;
  QVBoxLayout* layout = new QVBoxLayout(page);

  QLabel* label = new QLabel("This is Page 1");
  QPushButton* button = new QPushButton("Go to Page 2");

  layout->addWidget(label);
  layout->addWidget(button);

  connect(button, &QPushButton::clicked, this, [this]() {
    stack->setCurrentIndex(1);
  });

  return page;
}

QWidget* MainWindow::createPage2() {
  QWidget* page = new QWidget;
  QVBoxLayout* layout = new QVBoxLayout(page);

  auto *spec_plot = new SpectrumPlotWidget(this);
  QLabel* label = new QLabel("This is Page 2");
  QPushButton* button = new QPushButton("Go to Page 1");
  QPushButton* specFileBtn = new QPushButton("Load Spectrum");

  layout->addWidget(spec_plot);
  layout->addWidget(label);
  layout->addWidget(button);
  layout->addWidget(specFileBtn);

  connect(button, &QPushButton::clicked, this, [this]() {
    stack->setCurrentIndex(0);
  });

  connect(specFileBtn, &QPushButton::clicked, this, [this, spec_plot]() {
    QString fileName = QFileDialog::getOpenFileName(
        this,
        "Load Spectrum",
        "",
        "All Files (*)"
        );

    if (!fileName.isEmpty()) {
      std::cout << fileName.toStdString() << std::endl;
      pickett::SpeParseResult result = pickett::SpeParser::parse_file(fileName.toStdString());
      std::vector<double> freqs;
      std::vector<double> intensities;
      freqs.resize(result.npts);
      intensities.resize(result.npts);

      for (int i = 0; i < result.npts; ++i) {
        freqs[i] = result.footer.fstart + i * result.footer.fincr;
        intensities[i] = static_cast<double>(result.intensities[i]);
      }

      spec_plot->setSpectrum(freqs, intensities);
    }
  });

  return page;
}
