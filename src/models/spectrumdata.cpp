#include "spectrumdata.h"
#include "parsers/spe_parser.h"
#include <algorithm>
#include <iostream>

SpectrumData::SpectrumData(QObject *parent)
    : QObject(parent)
{
}

void SpectrumData::loadFile(const QString &filePath)
{
    // Convert file URL to local path if needed
    QString localPath = filePath;
    if (localPath.startsWith("file:///")) {
        localPath = localPath.mid(8);
    } else if (localPath.startsWith("file://")) {
        localPath = localPath.mid(7);
    }

    std::cout << "Loading: " << localPath.toStdString() << std::endl;

    pickett::SpeParseResult result = pickett::SpeParser::parse_file(localPath.toStdString());
    if (!result.success || result.npts <= 0) {
        std::cerr << "Failed to parse file or no data points" << std::endl;
        return;
    }

    std::vector<double> freqs;
    std::vector<double> intensities;
    freqs.resize(result.npts);
    intensities.resize(result.npts);

    for (int i = 0; i < result.npts; ++i) {
        freqs[i] = result.footer.fstart + i * result.footer.fincr;
        intensities[i] = static_cast<double>(result.intensities[i]);
    }

    decimate(freqs, intensities);

    m_xMin = *std::min_element(m_xData.begin(), m_xData.end());
    m_xMax = *std::max_element(m_xData.begin(), m_xData.end());
    m_yMin = *std::min_element(m_yData.begin(), m_yData.end());
    m_yMax = *std::max_element(m_yData.begin(), m_yData.end());

    m_fileName = filePath;
    emit dataChanged();
    emit fileNameChanged();
}

void SpectrumData::decimate(const std::vector<double> &freqs,
                            const std::vector<double> &intensities)
{
    const size_t target_buckets = 100000;

    if (freqs.size() > target_buckets * 2) {
        size_t bucket_size = freqs.size() / target_buckets;
        if (bucket_size < 2) bucket_size = 2;

        m_xData.clear();
        m_yData.clear();
        m_xData.reserve(target_buckets * 2);
        m_yData.reserve(target_buckets * 2);

        for (size_t i = 0; i < freqs.size(); i += bucket_size) {
            size_t end = std::min(i + bucket_size, freqs.size());

            auto min_it = std::min_element(intensities.begin() + i, intensities.begin() + end);
            auto max_it = std::max_element(intensities.begin() + i, intensities.begin() + end);

            size_t min_idx = static_cast<size_t>(std::distance(intensities.begin(), min_it));
            size_t max_idx = static_cast<size_t>(std::distance(intensities.begin(), max_it));

            if (min_idx < max_idx) {
                m_xData.push_back(freqs[min_idx]);
                m_yData.push_back(intensities[min_idx]);
                m_xData.push_back(freqs[max_idx]);
                m_yData.push_back(intensities[max_idx]);
            } else if (max_idx < min_idx) {
                m_xData.push_back(freqs[max_idx]);
                m_yData.push_back(intensities[max_idx]);
                m_xData.push_back(freqs[min_idx]);
                m_yData.push_back(intensities[min_idx]);
            } else {
                m_xData.push_back(freqs[min_idx]);
                m_yData.push_back(intensities[min_idx]);
            }
        }
    } else {
        m_xData = freqs;
        m_yData = intensities;
    }
}

const std::vector<double> &SpectrumData::xData() const { return m_xData; }
const std::vector<double> &SpectrumData::yData() const { return m_yData; }
double SpectrumData::xMin() const { return m_xMin; }
double SpectrumData::xMax() const { return m_xMax; }
double SpectrumData::yMin() const { return m_yMin; }
double SpectrumData::yMax() const { return m_yMax; }
QString SpectrumData::fileName() const { return m_fileName; }
