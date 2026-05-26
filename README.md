# Daywise

一款专注于**物品日均成本追踪**的 iOS 应用。记录每件物品的购入价格与使用时长，自动计算每天实际花了多少钱，帮你看清哪些东西真的值得买。

## 核心理念

> 一件 ¥3000 的耳机用了 3 年，日耗仅 ¥2.7；一件 ¥200 的T恤穿了 10 次就扔，日耗高达 ¥20。

**日耗（Cost Per Day）** = 购入价格 ÷ 服役天数（出售则扣除回收价）

## 功能

### 物品管理
- 添加物品：名称、价格、购入日期、分类、状态、备注
- 自定义分类：内置 8 个分类，支持新增自定义分类并持久化
- 三种状态：服役中 / 已退役 / 已出售（出售时记录回收价，自动计算净损耗）
- 编辑 & 删除，长按卡片可快速切换状态或删除

### 筛选 & 搜索
- 搜索栏：实时匹配名称、分类、备注
- 状态筛选：全部 / 服役中 / 已退役 / 已出售
- 分类筛选：按分类标签快速过滤
- 排序：最新录入 / 日耗最高 / 日耗最低 / 价格最高

### 统计看板
- 总览：物品总数、总投入、平均日耗、累计服役天数
- 状态分布：各状态占比进度条
- 分类分布：各分类数量与花费
- 排行榜：日耗最高 Top 3、最超值 Top 3（服役 ≥ 30 天）

### 数据导出
- 一键导出全部记录为 CSV 文件，可用 Numbers / Excel 打开分析

## 技术栈

| 项 | 详情 |
|---|---|
| 平台 | iOS 17+ |
| 语言 | Swift 5.9 |
| UI 框架 | SwiftUI |
| 数据持久化 | SwiftData |
| 架构 | MVVM-lite（View + @Model + Service） |

## 项目结构

```
Daywise/
├── DaywiseApp.swift          # App 入口，ModelContainer 配置
├── ContentView.swift         # TabView 根视图
├── Item.swift                # SwiftData 数据模型
│
├── Views/
│   ├── HomeView.swift        # 物品列表、搜索、筛选
│   ├── ItemCard.swift        # 物品卡片组件
│   ├── AddItemView.swift     # 添加物品表单
│   ├── EditItemView.swift    # 编辑物品表单
│   ├── DetailView.swift      # 物品详情页
│   ├── StatsView.swift       # 统计看板
│   └── SettingsView.swift    # 设置、CSV 导出
│
├── Services/
│   ├── CostCalculator.swift  # 日耗格式化工具
│   └── CategoryStore.swift   # 自定义分类持久化（@Observable）
│
└── Extensions/
    └── Color+Hex.swift       # Color(hex:) 扩展
```

## 运行方式

1. 克隆仓库
2. 用 Xcode 26+ 打开 `Daywise.xcodeproj`
3. 选择模拟器或真机（iOS 17+），Command + R 运行

无需任何第三方依赖，也无需配置 API Key 或账号。

## 开发者

[kok-s0s](https://github.com/kok-s0s)
