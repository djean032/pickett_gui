#include "mainwindow.h"

#include <QStackedWidget>
#include <QWidget>
#include <QVBoxLayout>
#include <QPushButton>
#include <QLabel>

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

// --- Page 2 ---
QWidget* MainWindow::createPage2() {
  QWidget* page = new QWidget;
  QVBoxLayout* layout = new QVBoxLayout(page);

  QLabel* label = new QLabel("This is Page 2");
  QPushButton* button = new QPushButton("Go to Page 1");

  layout->addWidget(label);
  layout->addWidget(button);

  connect(button, &QPushButton::clicked, this, [this]() {
    stack->setCurrentIndex(0);
  });

  return page;
}
