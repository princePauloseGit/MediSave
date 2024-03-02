codeunit 54100 "3M POS Reporting"
{
    trigger OnRun()
    var
        rec3MReporting: Record "3M PO Reporting";
    begin
        rec3MReporting.DeleteAll();
        CheckedForInvoice();
        CheckForCrMemo();
        SendEmail();
    end;

    procedure CheckedForInvoice()
    var
        recSalesInvoiceLine: Record "Sales Invoice Line";
        enumType: Enum "Sales Line Type";
        enumDocType: Enum "Sales Document Type";
    begin
        recSalesInvoiceLine.ReadIsolation := IsolationLevel::ReadCommitted;
        recSalesInvoiceLine.SetFilter("Item Category Code", '@3MLITTMANN*');
        recSalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        recSalesInvoiceLine.SetRange(Type, enumType::Item);
        recSalesInvoiceLine.SetRange("Posting Date", CalcDate('<-CM-1M>', Today), CalcDate('<CM-1M>', Today));
        recSalesInvoiceLine.SetAutoCalcFields("Ship-to Country/Region Code", "Bill-To City", "Bill-to County", "Bill-to Postcode", "Ship-To City", "Ship-to State", "Ship-to Postcode", "Sell-to Customer Name");
        recSalesInvoiceLine.SetFilter("Sell-to Customer Name", '<>%1 & <>%2', 'Amazon', 'Ebay');
        IF recSalesInvoiceLine.FindSet() then
            repeat
                InsertInto3MPOSReportingTbl(enumDocType::Invoice, recSalesInvoiceLine."Sell-to Customer No.", recSalesInvoiceLine."Ship-to Country/Region Code", recSalesInvoiceLine."Bill-To City", recSalesInvoiceLine."Bill-to County", recSalesInvoiceLine."Bill-to Postcode", recSalesInvoiceLine."No.", recSalesInvoiceLine.Description, recSalesInvoiceLine."Posting Date", recSalesInvoiceLine.Quantity, recSalesInvoiceLine."Line Amount", recSalesInvoiceLine."Ship-To City", recSalesInvoiceLine."Ship-to State", recSalesInvoiceLine."Ship-to Postcode");
            until recSalesInvoiceLine.Next() = 0;
    end;

    procedure CheckForCrMemo()
    var
        recSalescrMemoLine: Record "Sales Cr.Memo Line";
        enumType: Enum "Sales Line Type";
        enumDocType: Enum "Sales Document Type";
    begin
        recSalescrMemoLine.ReadIsolation := IsolationLevel::ReadCommitted;
        recSalescrMemoLine.SetFilter("Item Category Code", '3MLITTMANN*');
        recSalescrMemoLine.SetFilter(Quantity, '<>%1', 0);
        recSalescrMemoLine.SetRange(Type, enumType::Item);
        recSalescrMemoLine.SetRange("Posting Date", CalcDate('<-CM-1M>', Today), CalcDate('<CM-1M>', Today));
        recSalescrMemoLine.SetAutoCalcFields("Ship-to Country/Region Code", "Bill-To City", "Bill-to County", "Bill-to Postcode", "Ship-To City", "Ship-to State", "Ship-to Postcode");
        recSalescrMemoLine.SetFilter("Sell-to Customer Name", '<>%1 & <>%2', 'Amazon', 'Ebay');
        IF recSalescrMemoLine.FindSet() then
            repeat
                InsertInto3MPOSReportingTbl(enumDocType::"Credit Memo", recSalescrMemoLine."Sell-to Customer No.", recSalescrMemoLine."Ship-to Country/Region Code", recSalescrMemoLine."Bill-To City", recSalescrMemoLine."Bill-to County", recSalescrMemoLine."Bill-to Postcode", recSalescrMemoLine."No.", recSalescrMemoLine.Description, recSalescrMemoLine."Posting Date", recSalescrMemoLine.Quantity, recSalescrMemoLine."Line Amount", recSalescrMemoLine."Ship-To City", recSalescrMemoLine."Ship-to State", recSalescrMemoLine."Ship-to Postcode");
            until recSalescrMemoLine.Next() = 0;
    end;

    local procedure InsertInto3MPOSReportingTbl("Document Type": Enum "Sales Document Type"; "Sell-to Customer No.": Code[20]; "Ship-to Country/Region Code": Code[30]; "Bill-To City": Code[30]; "Bill-to County": Code[30]; "Bill-to Postcode": Code[30]; "No.": Code[20]; Description: Text[100]; "Posting Date": Date; Quantity: Decimal; "Line Amount": Decimal; "Ship-To City": Code[30]; "Ship-to State": Code[30]; "Ship-to Postcode": Code[30])
    var
        rec3MPOSReporting: Record "3M PO Reporting";
        recItme: Record Item;
    begin
        rec3MPOSReporting.Init();
        rec3MPOSReporting.Id := CreateGuid();
        rec3MPOSReporting.ShipToCustomerNumberDUNSNumber := "Sell-to Customer No.";
        rec3MPOSReporting."Ship To Customer Country" := "Ship-to Country/Region Code";
        rec3MPOSReporting."Bill To City" := "Bill-To City";
        rec3MPOSReporting."Bill To State" := "Bill-to County";
        rec3MPOSReporting."Bill To Postal Code" := "Bill-to Postcode";
        rec3MPOSReporting."Product Catalog #" := "No.";
        rec3MPOSReporting."Product Description" := Description;
        rec3MPOSReporting."Invoice Date" := "Posting Date";
        rec3MPOSReporting."Quantity Shipped/Returned" := Quantity;
        if "Document Type" = "Document Type"::"Credit Memo" then begin
            rec3MPOSReporting."Quantity Shipped/Returned" := Quantity * -1;
        end;
        rec3MPOSReporting."Unit of Measure" := 'EA';
        recItme.Get("No.");
        rec3MPOSReporting."Unit Distributor Cost" := recItme."Last Direct Cost";
        rec3MPOSReporting."Extended Distributor Cost" := recItme."Last Direct Cost";
        if ("Line Amount" <> 0) or (Quantity <> 0) then begin
            rec3MPOSReporting."Unit Selling Price" := "Line Amount" / Quantity;
        end;
        rec3MPOSReporting."Extended Selling Price" := "Line Amount";
        rec3MPOSReporting."Ship to City" := "Ship-To City";
        rec3MPOSReporting."Ship to State" := "Ship-to State";
        rec3MPOSReporting."Ship to Postal Code" := "Ship-to Postcode";
        rec3MPOSReporting.Insert();
    end;

    procedure SendEmail()
    var
        rec3MPOSReportingSetup: Record "3M POS Reporting Setup";
        rec3MReporting: Record "3M PO Reporting";
        cduEmailMessage: Codeunit "Email Message";
        cduEmail: Codeunit Email;
        cduAttachmentTempBlob: Codeunit "Temp Blob";
        cduFileMgt: Codeunit "File Management";
        rep3MPOSReporting: Report "3M POS Reporting";
        AttachmentInstream: InStream;
        AttachmentOustream: OutStream;
    begin
        if rec3MReporting.Count <> 0 then begin
            if rec3MPOSReportingSetup.FindSet() then
                repeat
                    rec3MReporting.ModifyAll("Distributor Prefix", rec3MPOSReportingSetup."Distributor Prefix", true);
                    cduEmailMessage.Create(rec3MPOSReportingSetup."Email Recipients", rec3MPOSReportingSetup."Email Subject", '');
                    cduAttachmentTempBlob.CreateOutStream(AttachmentOustream);
                    Report.SaveAs(Report::"3M POS Reporting", '', ReportFormat::Excel, AttachmentOustream);
                    cduAttachmentTempBlob.CreateInStream(AttachmentInstream);
                    cduEmailMessage.AddAttachment('3M POS Reporting.xlsx', 'XLSX', AttachmentInstream);
                    cduEmail.Send(cduEmailMessage);
                    Clear(cduAttachmentTempBlob);
                    Clear(AttachmentOustream);
                    Clear(AttachmentInstream);
                until rec3MPOSReportingSetup.Next() = 0;
        end;
        rec3MReporting.DeleteAll();
    end;
}