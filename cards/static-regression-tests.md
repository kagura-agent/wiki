---
title: Static Regression Tests
created: 2026-03-24
source: NemoClaw #330 (ericksoa) — credential exposure fix
last_verified: 2026-07-15
---
## Pattern
当修复安全/模式问题时，不只是修代码——写**静态扫描测试**防止回归。

## 具体做法
读源代码为纯文本（`fs.readFileSync`），用正则检查危险模式：
```javascript
const src = fs.readFileSync(FILE_PATH, "utf-8");
const violations = src.split("\n").filter(line => 
    DANGER_PATTERN.test(line) && !line.trimStart().startsWith("//")
);
expect(violations).toEqual([]);
```

## 优势
- **毫秒级运行** — 不需要 mock、不需要启动服务
- **永久防护** — 任何人再写出危险模式，CI 立刻报错
- **代码审计的自动化** — 把人工 review 的知识固化为测试

## 何时使用
- 修复安全问题（凭证泄露、注入、敏感数据）
- 修复模式问题（import 规范、命名约定）
- 任何"这个 bug 不应该再出现"的场景

## 来源
ericksoa 在 NemoClaw #330 用 83 行测试覆盖了 ~10 行代码改动。
我的 #382 修了同样的问题但没有回归测试——被关了。

## Links
- [[closed-pr-lessons]] — 被关闭 PR 的失败模式
- [[external-contributor-success]] — 外部贡献者成功模式
