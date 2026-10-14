# Release checklist (plan §11)

Automated (CI) | Manual (milestone)
---|---
- [x] Content validates; `--release` requires all reviews approved and 100% Kannada | - [ ] Airplane mode: onboarding, a full lesson and review on the reference phone
- [x] Pack N → N+1 update and corrupted-pack rollback (`pack_update_test.dart`) | - [ ] Same, over the air from the real CDN, on a phone
- [x] Every lesson card lays out at 130% and 200% text in English and Kannada | - [ ] Performance budgets (§8.6) on the reference phone, profile build
- [x] Text colours meet WCAG AA | - [ ] TalkBack walkthrough of every lesson
- [x] Kannada interface strings complete (gen-l10n untranslated check) | - [ ] No truncation at 200% on three phone brands
- [x] Every verse and translation carries source and licence | - [ ] Sources and licences screen reviewed by the library
- [x] targetSdk 36; 16 KB alignment check on the AAB | - [ ] App Bundle Explorer shows 16 KB support
- [ ] Pre-launch report clean | - [ ] Data safety form and privacy policy match the app
