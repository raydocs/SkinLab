# fn-13-tl5.1 数据加载分页

## Description
实现CheckIn列表分页加载，解决大量数据时的UI卡顿问题。

**当前问题**: @Query一次加载所有数据，100+条CheckIn时UI卡顿。

**目标**:
1. 实现虚拟化列表（LazyVStack + onAppear）
2. 或使用fetchLimit分页
3. 滚动时流畅加载更多
4. 100+ CheckIn时保持60fps

## Key Files
- `/SkinLab/Features/Tracking/Views/TrackingView.swift` - CheckIn列表
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift` - 报告数据

## Implementation Notes
```swift
// 方案1: 虚拟化列表
struct CheckInListView: View {
    @Query(sort: \CheckIn.date, order: .reverse)
    private var allCheckIns: [CheckIn]

    @State private var displayedCount = 20

    var body: some View {
        LazyVStack {
            ForEach(allCheckIns.prefix(displayedCount)) { checkIn in
                CheckInRow(checkIn: checkIn)
                    .onAppear {
                        if checkIn.id == allCheckIns.prefix(displayedCount).last?.id {
                            loadMore()
                        }
                    }
            }

            if displayedCount < allCheckIns.count {
                ProgressView()
                    .onAppear { loadMore() }
            }
        }
    }

    private func loadMore() {
        withAnimation {
            displayedCount = min(displayedCount + 20, allCheckIns.count)
        }
    }
}

// 方案2: fetchLimit (需要手动管理offset)
// @Query(sort: \CheckIn.date, order: .reverse, animation: .default)
// 配合 FetchDescriptor 的 fetchLimit 和 fetchOffset
```

## Acceptance
- [ ] CheckIn列表支持分页/虚拟化
- [ ] 滚动到底部自动加载更多
- [ ] 100+ CheckIn时滚动流畅(60fps)
- [ ] 加载更多时有loading指示
- [ ] 无内存泄漏

## Quick Commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
