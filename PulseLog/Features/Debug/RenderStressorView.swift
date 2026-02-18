import SwiftUI

struct RenderStressorView: View {
    @StateObject private var viewModel = RenderStressorViewModel()
    @State private var useBrokenWrapper = true
    @State private var useLazyStack = true
    @State private var updateTick = 0

    var body: some View {
        VStack(spacing: 10) {
            Toggle("Broken: @StateObject in row", isOn: $useBrokenWrapper)
            Toggle("Use LazyVStack", isOn: $useLazyStack)

            Text("Broken VM initializations: \(viewModel.brokenVMInitCount)")
                .font(.caption)
                .foregroundStyle(useBrokenWrapper ? .orange : .secondary)

            ScrollView {
                if useLazyStack {
                    LazyVStack(spacing: 8) {
                        rows
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        rows
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.horizontal)
        .navigationTitle("Render Stressor")
        .onChange(of: useBrokenWrapper) { _, isBroken in
            if isBroken {
                viewModel.resetBrokenCounter()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                updateTick += 1
            }
        }
    }

    @ViewBuilder
    private var rows: some View {
        if useBrokenWrapper {
            ForEach(viewModel.entries) { entry in
                // Intentional misuse: each body pass allocates a new VM but @StateObject keeps the first one.
                // The throwaway allocations are visible via the init counter and in Allocations instrument.
                BrokenRenderRow(viewModel: viewModel.makeBrokenViewModel(for: entry), updateTick: updateTick)
            }
        } else {
            ForEach(viewModel.fixedRowViewModels) { rowViewModel in
                FixedRenderRow(viewModel: rowViewModel, updateTick: updateTick)
            }
        }
    }
}

private struct BrokenRenderRow: View {
    @StateObject private var viewModel: RenderRowViewModel
    @State private var renderCount = 0
    let updateTick: Int

    init(viewModel: RenderRowViewModel, updateTick: Int) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.updateTick = updateTick
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.title)
                Text(viewModel.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("renders: \(renderCount)")
                .font(.caption2)
        }
        .padding(10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            renderCount += 1
        }
        .onChange(of: updateTick) { _, _ in
            renderCount += 1
        }
    }
}

private struct FixedRenderRow: View {
    @ObservedObject var viewModel: RenderRowViewModel
    @State private var renderCount = 0
    let updateTick: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.title)
                Text(viewModel.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("renders: \(renderCount)")
                .font(.caption2)
        }
        .padding(10)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            renderCount += 1
        }
        .onChange(of: updateTick) { _, _ in
            renderCount += 1
        }
    }
}
