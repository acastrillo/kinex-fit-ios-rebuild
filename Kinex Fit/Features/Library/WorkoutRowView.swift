import SwiftUI

/// A single row in the workout list, showing title, source badge, and timestamp.
struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Text(workout.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                SourceBadge(source: workout.source)
            }

            if let content = workout.content, !content.isBlank {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(workout.updatedAt.relativeString)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppTheme.spacingXS)
    }
}

// MARK: - Source Badge

private struct SourceBadge: View {
    let source: WorkoutSource

    var body: some View {
        Text(source.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, AppTheme.spacingSM)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2))
            .foregroundStyle(backgroundColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch source {
        case .manual: .blue
        case .ocr: .purple
        case .instagram: .pink
        case .imported: .orange
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        WorkoutRowView(workout: MockData.workouts[0])
        WorkoutRowView(workout: MockData.workouts[2])
        WorkoutRowView(workout: MockData.workouts[3])
    }
    .withPreviewEnvironment()
}
