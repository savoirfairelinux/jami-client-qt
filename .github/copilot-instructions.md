# Jami Client Qt — Coding Rules & Skills

## Project Identity

Qt 6.8 / QML application for the Jami distributed communication platform.
- Languages: C++20 (logic), QML (UI), Python 3 (tooling)
- Build: CMake 3.19+, Qt 6.8+
- Formatter: `python3 extras/scripts/format.py` (clang-format + qmlformat)
- Review: Gerrit at `review.jami.net` — **not GitHub PRs**

Specialized agents for focused tasks: see `.github/agents/`.

---

## Skill: Write C++ (adapter or model)

1. Place adapters in `src/app/`, models/interfaces in `src/libclient/api/`.
2. Expose to QML via `Q_PROPERTY(Type name READ get NOTIFY nameChanged)`.
3. Mark callable slots as `Q_INVOKABLE`.
4. Connect to libclient signals in the adapter constructor with `QObject::connect`.
5. Emit targeted signals — never broad `dataChanged()` resets.
6. Apply `.clang-format` rules: 120-column limit, 4-space indent, pointer-left.

**Pattern**:
```cpp
// header
Q_PROPERTY(QString displayName READ displayName NOTIFY displayNameChanged)
Q_INVOKABLE void sendMessage(const QString& text);

// .cpp — adapter constructor
connect(model, &ConversationModel::messageAdded, this, [this](const QString& id) {
    emit messageReceived(id);
});
```

---

## Skill: Write QML Component

1. New shared components → `src/app/commoncomponents/PascalCaseName.qml`.
2. Feature-specific → `src/app/mainview/components/` or appropriate view folder.
3. Register in the `qmldir` or re-run `extras/scripts/gen_qml_qrc.py`.
4. IDs and properties: `camelCase`. File/type names: `PascalCase`.
5. Bind to adapter properties; call `Q_INVOKABLE` slots for actions.
6. Localize all user-visible text with `qsTr()`.
7. Format with `qmlformat` via `format.py`.

**Pattern**:
```qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property string title: ""
    signal accepted()

    Text {
        text: qsTr(root.title)
    }
}
```

---

## Skill: Add a Feature End-to-End

1. **Daemon signal** → connect in adapter constructor (libclient → adapter).
2. **Adapter** → emit Qt signal; expose data via `Q_PROPERTY`.
3. **QML** → `Connections { target: MyAdapter; function onXxxChanged() { … } }`.
4. **Test** → add a GTest case in `tests/unittests/` for the C++ logic.

---

## Skill: Run / Write Tests

- Unit tests (GTest): `tests/unittests/`
- QML integration tests: `tests/qml/`
- Build & run: `cmake -Bbuild -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build`
- Tests run on offscreen platform for headless/CI environments.
- Always add a test for new C++ logic before marking a task done.

---

## Skill: Format & Lint

```bash
# Format all C++ and QML files
python3 extras/scripts/format.py

# Install pre-commit hook (run once after cloning)
python3 build.py --init --qt=/usr/lib/libqt-jami
```

`.clang-format` key rules: ColumnLimit 120, IndentWidth 4, PointerAlignment Left,
BinPackArguments false, BreakBeforeBraces Custom (braces after functions/classes/structs).

---

## Hard Constraints

- No daemon API calls from QML JavaScript — route through C++ adapters.
- No hardcoded user-visible strings — always `qsTr()` / `tr()`.
- No new third-party dependencies without updating `3rdparty/` and `CMakeLists.txt`.
- No `--no-verify` or hook bypass.
- No force-push to `master`.
