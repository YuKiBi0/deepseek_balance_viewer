# 多密钥 / 多标签切换余额查看 实现计划

## 概述

将当前仅支持单把 API Key 的 DeepSeek 余额查看器，升级为支持多把密钥的版本：

* 可同时存储多把密钥，每把密钥带一个**必填昵称**作为标签名。

* 首页顶部以**可滚动的 TabBar** 展示各密钥标签，切换标签即查看对应密钥余额。

* 余额按需加载并缓存：首次进入某标签才请求，之后切换即时显示。

## 当前状态分析

现有代码为扁平结构，全部位于 `lib/`：

| 文件                          | 职责                                                                     |
| --------------------------- | ---------------------------------------------------------------------- |
| `lib/main.dart`             | 入口 + `SplashScreen`，读取单把密钥 `deepseek_api_key`，据此跳转 `/apikey` 或 `/home` |
| `lib/deepseek_service.dart` | `fetchBalance(String apiKey)`，已按入参 key 请求，**无需改动**                     |
| `lib/api_key_screen.dart`   | 单把密钥输入页，保存到 `deepseek_api_key`                                         |
| `lib/home_screen.dart`      | 读取单把密钥并展示余额                                                            |
| `pubspec.yaml`              | 依赖：`shared_preferences`、`http`；**无需新增依赖**                              |

存储现状：仅 `deepseek_api_key`（String）一个字段，无“多把密钥/当前选中”的概念。

## 变更方案

### 数据与存储格式（SharedPreferences）

* `deepseek_api_keys`（String）：JSON 数组，元素结构：

  ```json
  { "id": "时间有序唯一串", "name": "昵称", "key": "sk-..." }
  ```

* `active_api_key_id`（String）：当前选中密钥的 `id`。

* 旧字段 `deepseek_api_key`：仅用于迁移，迁移完成后删除。

### 新增文件

#### 1. `lib/models/api_key_entry.dart`（数据模型）

* `class ApiKeyEntry`，字段：`String id`、`String name`、`String apiKey`。

* 构造器 `ApiKeyEntry({required this.id, required this.name, required this.apiKey})`。

* `String get maskedKey`：当 `apiKey.length > 8` 时返回 `前3位...后4位`，否则返回原文；用于列表中展示脱敏密钥。

* `Map<String, dynamic> toJson()` 与 `factory ApiKeyEntry.fromJson(Map<String, dynamic>)`。

#### 2. `lib/services/key_store.dart`（服务层，承载业务逻辑）

静态常量：`_keysKey = 'deepseek_api_keys'`、`_activeKey = 'active_api_key_id'`、`_legacyKey = 'deepseek_api_key'`。

方法（均异步，内部用 `SharedPreferences.getInstance()`）：

* `Future<List<ApiKeyEntry>> loadKeys()`

  * 读取 `deepseek_api_keys`，非空则解码返回。

  * 若为空且旧 `deepseek_api_key` 非空：迁移为单条 `ApiKeyEntry(name: '默认', ...)`，写入新字段、删除旧字段、设为 active 并返回。

  * 否则返回空列表。

* `Future<String?> loadActiveId()`：返回 `active_api_key_id`。

* `Future<void> addKey(ApiKeyEntry entry)`：追加到列表并写回。

* `Future<void> updateKey(ApiKeyEntry entry)`：按 `id` 替换并写回。

* `Future<void> deleteKey(String id)`：按 `id` 移除并写回。

* `Future<void> setActive(String id)`：写入 `active_api_key_id`。

* 私有 `Future<void> _saveKeys(List<ApiKeyEntry>)`、`Future<void> _saveActive(String?)`。

* 私有 `String _genId()`：生成时间有序唯一 ID，如 `'${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0xFFFFFF)}'`（避免新增 uuid 依赖）。

### 修改文件

#### 3. `lib/api_key_screen.dart` → 改为“密钥管理”页

* 标题改为“密钥管理”。

* `initState` 加载 `KeyStore().loadKeys()` + `loadActiveId()`。

* 列表展示每把密钥：`ListTile`，`title` 为昵称，`subtitle` 为 `maskedKey`；`trailing` 为删除 `IconButton`；`leading` 用 `Icon(Icons.check_circle)` 高亮当前 active。

* 点击列表项 → `Navigator.push(MaterialPageRoute(builder: (_) => KeyEditScreen(entry: e)))` 进入编辑。

* `FloatingActionButton`（`Icons.add`）→ 进入 `KeyEditScreen()` 新增。

* 删除逻辑：`deleteKey(id)`；若删除的是 active，则把第一条剩余密钥设为 active（`setActive`）。

* 页面返回时（`await` 导航结果）重新 `loadKeys` 刷新列表。

#### 4. 新增 `lib/key_edit_screen.dart`（新增/编辑单把密钥）

* 可选入参 `final ApiKeyEntry? entry;`（null 表示新增）。

* 两个输入框：昵称（必填）、API Key（必填，`obscureText` 或明文均可，建议明文便于粘贴）。

* 校验：任一为空则提示错误（沿用现有 `_error` 模式）。

* 保存：

  * 新增：`KeyStore().addKey(...)`，并 `setActive(新 id)`。

  * 编辑：`KeyStore().updateKey(...)`。

  * 完成后：`if (Navigator.canPop(context)) Navigator.pop(context) else Navigator.pushReplacementNamed(context, '/home')`，以兼容“首次启动无密钥直接进本页”的场景。

#### 5. `lib/home_screen.dart` → 多标签 + 缓存

* 状态新增：`List<ApiKeyEntry> _keys`、`String? _activeId`、`TabController? _tabController`（`SingleTickerProviderStateMixin`）。

* 缓存结构（按密钥 `id` 索引）：

  * `Map<String, Map<String, dynamic>> _balances`

  * `Map<String, String> _errors`

  * `Set<String> _loading`

* `initState`：加载 `_keys` 与 `_activeId`；若 `_keys` 为空 → 跳转到新增密钥页（`KeyEditScreen`）；否则初始化 `TabController(initialIndex: active 所在下标)`，并对 active 标签触发加载。

* 顶部：`AppBar.bottom` 放 `TabBar(isScrollable: true)`，标签为各密钥 `name`；`TabBarView` 中每个标签用 `_buildKeyView(key)` 渲染。

* `_buildKeyView(key)`：若 `_balances[key.id]` 存在则展示余额；若 `_errors[key.id]` 存在则展示错误 + 重试；否则显示 loading 并在 `initState`/首次构建时触发 `_fetchBalance(key)`。

* `_fetchBalance(key)`：置 loading、清 error，调用 `DeepSeekService.fetchBalance(key.apiKey)`，成功后写入 `_balances[key.id]`，失败写入 `_errors[key.id]`。

* 切换标签时（`TabBar` 的 `onTap`）更新 `_activeId` 并 `KeyStore().setActive(id)` 持久化；对无缓存的标签触发加载。

* 刷新按钮：清除 active 密钥缓存后重新 `_fetchBalance`。

* 余额展示：复用现有 `_infoRow` 与卡片布局（`is_available`、`balance_infos`），仅把数据源从单字段改为按 `_balances[key.id]` 取值。当前“更换 API Key”按钮改为跳转到 `/keys` 管理页（`IconButton` 或 AppBar action）。

#### 6. `lib/main.dart` → 路由与启动逻辑

* `routes` 调整：

  * `/` → `SplashScreen`

  * `/keys` → `ApiKeyScreen`（密钥管理）

  * `/home` → `HomeScreen`

  * （`/key-edit` 不注册命名路由，统一用 `MaterialPageRoute` 传递可选 `entry`）

* `SplashScreen._checkApiKey` 改为 `_checkKeys`：

  ```dart
  final keys = await KeyStore().loadKeys();
  if (keys.isEmpty) {
    Navigator.pushReplacement(MaterialPageRoute(builder: (_) => const KeyEditScreen()));
  } else {
    Navigator.pushReplacementNamed('/home');
  }
  ```

## 假设与决策

* 标签名使用**用户自定义昵称（必填）**（用户已确认）。

* 余额采用**切换时按需加载 + 缓存**（用户已确认）。

* 沿用 `shared_preferences`，不引入 `uuid` 等新依赖，ID 用时间戳 + 随机数生成。

* 旧单密钥 `deepseek_api_key` 自动迁移，昵称取“默认”。

* 保持业务逻辑集中在 `KeyStore` 服务层，`deepseek_service.dart` 不变。

* 现有 `test/widget_test.dart` 仅断言 `SplashScreen` 存在，仍会通过，无需改动。

## 验证步骤

1. `flutter analyze` 无错误。
2. 全新启动（无密钥）→ 直接进入“新增密钥”页 → 填写昵称 + key → 保存后进入首页并显示余额。
3. 首页顶部出现标签；点右上角管理按钮进入“密钥管理”页。
4. 新增第二把密钥 → 返回首页出现两个标签，可快速切换查看各自余额（切换后已缓存即时显示）。
5. 编辑昵称/key、删除密钥，删除 active 后 active 自动切换；重启应用后密钥与当前选中标签均保留。
6. 旧版本单密钥用户升级后，首次启动自动迁移为“默认”标签并显示余额。

