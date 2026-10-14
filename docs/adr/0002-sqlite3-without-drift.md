# 2. sqlite3 directly instead of drift

Status: accepted. **Deviation from plan §6.3.**

The plan lists `drift` for databases. `content.db` is read-only with hand-written
queries, so drift's table classes would add generated code with no benefit. `user.db`
has six small tables; a list of SQL migrations run in order inside transactions
(`UserStore.migrations`, tested) is simpler than drift's codegen and migration tooling.

Screens reach storage only through `ContentRepository` and `UserStore`, so switching
to drift later touches only those two classes. Revisit if `user.db` grows many tables
or needs reactive queries.
