import os, re
files = [
    r'c:\proj\payme\lib\services\pdf_generation_service.dart',
    r'c:\proj\payme\lib\presentation\features\reports\screens\payments_by_period_report_screen.dart',
    r'c:\proj\payme\lib\presentation\features\reports\screens\paid_invoices_report_screen.dart',
    r'c:\proj\payme\lib\presentation\features\reports\screens\outstanding_invoices_report_screen.dart',
    r'c:\proj\payme\lib\presentation\features\reports\screens\invoices_by_period_report_screen.dart',
    r'c:\proj\payme\lib\presentation\features\reports\screens\client_balances_report_screen.dart',
    r'c:\proj\payme\lib\presentation\features\payments\widgets\payment_tile.dart',
    r'c:\proj\payme\lib\presentation\features\dashboard\screens\dashboard_screen.dart',
    r'c:\proj\payme\lib\presentation\features\invoices\screens\global_invoice_list_screen.dart',
    r'c:\proj\payme\lib\presentation\features\clients\widgets\ledger_summary_card.dart',
    r'c:\proj\payme\lib\presentation\features\clients\screens\client_ledger_screen.dart'
]
for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'toStringAsFixed(2)' in content:
        parts = file.replace('c:\\proj\\payme\\lib\\', '').split('\\')
        depth = len(parts) - 1
        import_path = '../' * depth + 'core/formatters/formatters.dart'
        if not 'NumberFormatter' in content:
            content = re.sub(r'^(import .*?;)', f"import '{import_path}';\n\\1", content, count=1, flags=re.MULTILINE)
        content = re.sub(r'([a-zA-Z0-9_\.]+)\.toStringAsFixed\(2\)', r'NumberFormatter.formatAmount(\1)', content)
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Updated ' + file)
