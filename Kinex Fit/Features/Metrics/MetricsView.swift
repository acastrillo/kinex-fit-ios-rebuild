import SwiftUI
import Charts

/// The Metrics tab — displays body weight tracking with a chart and history list.
struct MetricsView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: MetricsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                MetricsContent(viewModel: viewModel, syncEngine: environment.syncEngine)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = MetricsViewModel(bodyMetricRepository: environment.bodyMetricRepository, syncEngine: environment.syncEngine)
                vm.startObserving()
                viewModel = vm
            }
        }
    }
}

// MARK: - Metrics Content

private struct MetricsContent: View {
    @Bindable var viewModel: MetricsViewModel
    let syncEngine: SyncEngine

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.metrics.isEmpty {
                    ContentUnavailableView(
                        "No Measurements",
                        systemImage: AppTheme.TabIcon.metrics,
                        description: Text("Tap + to log your first weigh-in")
                    )
                } else {
                    metricsContent
                }
            }
            .navigationTitle("Metrics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddMetric = true
                    } label: {
                        Image(systemName: AppTheme.Icon.add)
                    }
                }
            }
            .syncStatusToolbar(syncEngine: syncEngine)
            .sheet(isPresented: $viewModel.showAddMetric) {
                AddMetricView()
            }
            .confirmationDialog(
                "Delete Entry",
                isPresented: $viewModel.showDeleteConfirmation,
                presenting: viewModel.metricToDelete
            ) { metric in
                Button("Delete", role: .destructive) {
                    viewModel.deleteMetric(metric)
                }
            } message: { metric in
                Text("Delete the entry from \(metric.date.shortDateString)?")
            }
        }
    }

    // MARK: - Content

    private var metricsContent: some View {
        List {
            // Summary card
            Section {
                summaryCard
            }

            // Weight chart
            if viewModel.chartData.count >= 2 {
                Section("Trend") {
                    weightChart
                        .frame(height: 180)
                        .listRowInsets(EdgeInsets(
                            top: AppTheme.spacingMD,
                            leading: AppTheme.spacingLG,
                            bottom: AppTheme.spacingMD,
                            trailing: AppTheme.spacingLG
                        ))
                }
            }

            // History
            Section("History") {
                ForEach(viewModel.metrics) { metric in
                    MetricRowView(metric: metric)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.confirmDelete(metric)
                            } label: {
                                Label("Delete", systemImage: AppTheme.Icon.delete)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: AppTheme.spacingXL) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Current")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let weight = viewModel.latestWeight {
                    Text(String(format: "%.1f", weight))
                        .font(.title)
                        .fontWeight(.bold)
                    + Text(" lbs")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text("—")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                }
            }

            if let change = viewModel.weightChange {
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text("Change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up.right" : change < 0 ? "arrow.down.right" : "arrow.right")
                            .font(.caption)
                        Text(String(format: "%+.1f lbs", change))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(change > 0 ? .red : change < 0 ? .green : .secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Weight Chart

    private var weightChart: some View {
        Chart(viewModel.chartData) { metric in
            LineMark(
                x: .value("Date", metric.date),
                y: .value("Weight", metric.weight)
            )
            .foregroundStyle(.accent)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", metric.date),
                y: .value("Weight", metric.weight)
            )
            .foregroundStyle(.accent.opacity(0.1))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", metric.date),
                y: .value("Weight", metric.weight)
            )
            .foregroundStyle(.accent)
            .symbolSize(20)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }
}

// MARK: - Metric Row

struct MetricRowView: View {
    let metric: BodyMetric

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(metric.date.shortDateString)
                    .font(.subheadline)

                if let notes = metric.notes, !notes.isBlank {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(String(format: "%.1f lbs", metric.weight))
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, AppTheme.spacingXS)
    }
}

// MARK: - Preview

#Preview {
    MetricsView()
        .withPreviewEnvironment()
}
