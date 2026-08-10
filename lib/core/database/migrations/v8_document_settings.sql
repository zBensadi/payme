ALTER TABLE business_settings ADD COLUMN default_document_title TEXT NOT NULL DEFAULT 'Invoice';
ALTER TABLE business_settings ADD COLUMN default_document_layout TEXT NOT NULL DEFAULT 'standard';
