-- content.db, schema_version 1 (plan Appendix B). Read-only on the phone.
-- Additive changes only; a breaking change bumps schema_version (plan §6.2).

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);

CREATE TABLE localized_text (
  entity_id TEXT NOT NULL, field TEXT NOT NULL, locale TEXT NOT NULL, text TEXT NOT NULL,
  PRIMARY KEY (entity_id, field, locale)
) WITHOUT ROWID;

CREATE TABLE licence (id TEXT PRIMARY KEY, name TEXT NOT NULL, url TEXT NOT NULL,
  commercial_use INTEGER NOT NULL, share_alike INTEGER NOT NULL);
CREATE TABLE source (id TEXT PRIMARY KEY, citation TEXT NOT NULL, url TEXT, licence_id TEXT NOT NULL,
  attribution TEXT, kind TEXT NOT NULL);

CREATE TABLE work (id TEXT PRIMARY KEY, title_iast TEXT NOT NULL, author_id TEXT NOT NULL,
  year_from INTEGER NOT NULL, year_to INTEGER NOT NULL, source_id TEXT NOT NULL,
  licence_id TEXT NOT NULL, text_form TEXT);
CREATE TABLE section (id TEXT PRIMARY KEY, work_id TEXT NOT NULL, parent_id TEXT,
  ordinal INTEGER NOT NULL);
CREATE TABLE verse (id TEXT PRIMARY KEY, work_id TEXT NOT NULL, section_id TEXT NOT NULL,
  ordinal INTEGER NOT NULL, ref_label TEXT NOT NULL, review TEXT NOT NULL, has_audio INTEGER NOT NULL DEFAULT 0);
CREATE INDEX verse_work ON verse (work_id, ordinal);
CREATE TABLE verse_text (verse_id TEXT NOT NULL, script TEXT NOT NULL, text TEXT NOT NULL,
  PRIMARY KEY (verse_id, script)) WITHOUT ROWID;

CREATE TABLE translation (id TEXT PRIMARY KEY, translator TEXT NOT NULL, year INTEGER NOT NULL,
  language TEXT NOT NULL, kind TEXT NOT NULL, licence_id TEXT NOT NULL, source_id TEXT NOT NULL);
CREATE TABLE translation_work (translation_id TEXT NOT NULL, work_id TEXT NOT NULL,
  verses_covered INTEGER NOT NULL, verses_total INTEGER NOT NULL,
  PRIMARY KEY (translation_id, work_id)) WITHOUT ROWID;
CREATE TABLE translation_segment (id TEXT PRIMARY KEY, translation_id TEXT NOT NULL,
  ordinal INTEGER NOT NULL, label TEXT, text TEXT NOT NULL, page TEXT NOT NULL, status TEXT NOT NULL);
CREATE TABLE segment_verse (segment_id TEXT NOT NULL, verse_id TEXT NOT NULL,
  PRIMARY KEY (segment_id, verse_id)) WITHOUT ROWID;
CREATE INDEX segment_verse_by_verse ON segment_verse (verse_id);
CREATE TABLE segment_glossary (segment_id TEXT NOT NULL, glossary_id TEXT NOT NULL,
  PRIMARY KEY (segment_id, glossary_id)) WITHOUT ROWID;

CREATE TABLE term (id TEXT PRIMARY KEY, devanagari TEXT NOT NULL, kannada TEXT NOT NULL,
  iast TEXT NOT NULL, ascii_key TEXT NOT NULL, concept_id TEXT);
CREATE TABLE verse_term (verse_id TEXT NOT NULL, term_id TEXT NOT NULL,
  PRIMARY KEY (verse_id, term_id)) WITHOUT ROWID;
CREATE TABLE glossary (id TEXT PRIMARY KEY, headword TEXT NOT NULL);

CREATE TABLE area (id TEXT PRIMARY KEY, ordinal INTEGER NOT NULL, sanskrit_iast TEXT NOT NULL);
CREATE TABLE concept (id TEXT PRIMARY KEY, area_id TEXT NOT NULL, classical_iast TEXT NOT NULL);
CREATE TABLE concept_relation (from_id TEXT NOT NULL, to_id TEXT NOT NULL, type TEXT NOT NULL,
  PRIMARY KEY (from_id, to_id, type)) WITHOUT ROWID;
CREATE TABLE concept_verse (concept_id TEXT NOT NULL, verse_id TEXT NOT NULL, role TEXT NOT NULL,
  PRIMARY KEY (concept_id, verse_id)) WITHOUT ROWID;
CREATE TABLE concept_person (concept_id TEXT NOT NULL, mathematician_id TEXT NOT NULL,
  PRIMARY KEY (concept_id, mathematician_id)) WITHOUT ROWID;

CREATE TABLE place (id TEXT PRIMARY KEY, lat REAL NOT NULL, lon REAL NOT NULL);
CREATE TABLE mathematician (id TEXT PRIMARY KEY, name_iast TEXT NOT NULL,
  born_from INTEGER, born_to INTEGER, died_from INTEGER, died_to INTEGER, place_id TEXT,
  sort_year INTEGER NOT NULL);
CREATE TABLE teacher_of (teacher_id TEXT NOT NULL, student_id TEXT NOT NULL, source_id TEXT NOT NULL,
  note TEXT, PRIMARY KEY (teacher_id, student_id)) WITHOUT ROWID;
CREATE TABLE authored (mathematician_id TEXT NOT NULL, work_id TEXT NOT NULL,
  PRIMARY KEY (mathematician_id, work_id)) WITHOUT ROWID;

CREATE TABLE curriculum_node (id TEXT PRIMARY KEY, board TEXT NOT NULL, class INTEGER NOT NULL,
  book TEXT NOT NULL, chapter_no INTEGER NOT NULL, parent_id TEXT);
CREATE TABLE curriculum_link (node_id TEXT NOT NULL, entity_id TEXT NOT NULL, relevance TEXT NOT NULL,
  ordinal INTEGER NOT NULL, PRIMARY KEY (node_id, entity_id)) WITHOUT ROWID;

CREATE TABLE lesson (id TEXT PRIMARY KEY, version INTEGER NOT NULL, minutes INTEGER NOT NULL,
  area_id TEXT NOT NULL, doc_json TEXT NOT NULL);
CREATE TABLE lesson_concept (lesson_id TEXT NOT NULL, concept_id TEXT NOT NULL,
  PRIMARY KEY (lesson_id, concept_id)) WITHOUT ROWID;
CREATE TABLE problem_template (id TEXT PRIMARY KEY, lesson_id TEXT NOT NULL, generator_id TEXT NOT NULL,
  params_json TEXT NOT NULL);

CREATE TABLE media (id TEXT PRIMARY KEY, provider TEXT NOT NULL, external_id TEXT NOT NULL,
  speaker TEXT NOT NULL, organisation TEXT NOT NULL, licence_id TEXT NOT NULL,
  duration_s INTEGER NOT NULL, level TEXT NOT NULL);
CREATE TABLE media_segment (id TEXT PRIMARY KEY, media_id TEXT NOT NULL, start_s INTEGER NOT NULL,
  end_s INTEGER NOT NULL, checked_by TEXT, checked_on TEXT);

CREATE TABLE claim_source (entity_id TEXT NOT NULL, field TEXT NOT NULL, source_id TEXT NOT NULL,
  note TEXT, PRIMARY KEY (entity_id, field, source_id)) WITHOUT ROWID;

CREATE TABLE timeline_event (id TEXT PRIMARY KEY, year_from INTEGER NOT NULL, year_to INTEGER NOT NULL,
  region TEXT NOT NULL, source_id TEXT NOT NULL, source_note TEXT);
CREATE TABLE timeline_link (event_id TEXT NOT NULL, entity_id TEXT NOT NULL,
  PRIMARY KEY (event_id, entity_id)) WITHOUT ROWID;

CREATE TABLE redirect (old_id TEXT PRIMARY KEY, new_id TEXT NOT NULL);

-- Search (plan §6.9). `text` is human text in the row's locale; `keys` holds
-- plain-ASCII keys so a query in any script can be folded and matched.
CREATE VIRTUAL TABLE search_index USING fts5(
  entity_type UNINDEXED, entity_id UNINDEXED, locale UNINDEXED, title UNINDEXED, text, keys,
  tokenize = "unicode61 remove_diacritics 2 tokenchars '्್'"
);
