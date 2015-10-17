print Files::all_registered_mime_types();
const pdf_mime_types = { "application/pdf" };
const pe_mime_types = { "application/x-dosexec" };
Files::register_for_mime_types(Files::ANALYZER_EXTRACT, pdf_mime_types);
Files::register_for_mime_types(Files::ANALYZER_PE, pe_mime_types);
print Files::all_registered_mime_types();
