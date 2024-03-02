codeunit 54106 SplitOrders
{
    var
        enum_DocumentType: Enum "Sales Document Type";
        rec_SalesLines: Record "Sales Line";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        recItem: Record Item;

    procedure checkSalesLines(recShoify: Record "Sales Header")
    var
        recSalesHeader, recEmbro, recPharma : Record "Sales Header";
        rec_SalesLines: Record "Sales Line";
        isPharma, isEmbroidery, isNotPharmaItem, isNotEmbro : Boolean;
        recItem: Record Item;
        enumSalesItem: Enum "Sales Line Type";
        itemCount, pharmaCount, embroCount, standardCount : Integer;
        Personalisation: Text;
    begin
        ReleaseSalesDoc.Reopen(recShoify);
        isPharma := false;
        isEmbroidery := false;
        isNotPharmaItem := false;
        isNotEmbro := false;

        pharmaCount := 0;
        itemCount := 0;
        embroCount := 0;
        standardCount := 0;

        rec_SalesLines.Reset();
        rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
        rec_SalesLines.SetRange("Document No.", recShoify."No.");
        rec_SalesLines.SetRange(Type, enumSalesItem::Item);

        if rec_SalesLines.FindSet() then begin
            repeat
                isNotPharmaItem := false;
                isNotEmbro := false;

                itemCount := rec_SalesLines.Count();

                recItem.Reset();
                recItem.SetRange("No.", rec_SalesLines."No.");
                recItem.SetRange(enhPharma, true);
                if recItem.FindFirst() then begin
                    isPharma := true;
                    pharmaCount := pharmaCount + 1;
                end else begin
                    isNotPharmaItem := true;
                end;

                Clear(Personalisation);

                Personalisation := rec_SalesLines.Personalisation.ToUpper();

                if Personalisation = 'EMBROIDERY' then begin
                    isEmbroidery := true;
                    embroCount := embroCount + 1;
                end else begin
                    isNotEmbro := true;
                end;

                if isNotEmbro = true and isNotPharmaItem = true then begin
                    standardCount := standardCount + 1;
                end;

            until rec_SalesLines.Next() = 0;
        end;

        //Order contains only standard
        if (standardCount = itemCount) then begin
            RemoveLinesOfOrgSO(recShoify, 'Standard');
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;

        //Order contains only pharma items.
        if (itemCount = pharmaCount) then begin

            RemoveLinesOfOrgSO(recShoify, 'Pharma');
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;

        //Order contains only embroidered items
        if (itemCount = embroCount) then begin

            RemoveLinesOfOrgSO(recShoify, 'Embroidered');
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;

        //Order contains standard & pharma items
        if (itemCount <> pharmaCount) and (standardCount >= 1) and (pharmaCount >= 1) and (embroCount <= 0) then begin
            recPharma := createNewSalesOrder(recShoify."No.");
            RemoveEmbroideryandStandardLinesFromOrder(recPharma);
            RemoveLinesOfOrgSO(recShoify, 'Std&Pharma');
            ReleaseSalesDoc.ReleaseSalesHeader(recPharma, false);
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;

        //Order contains standard & embroidered item
        if (standardCount >= 1) and (embroCount >= 1) and (itemCount <> embroCount) and (pharmaCount <= 0) then begin
            recEmbro := createNewSalesOrder(recShoify."No.");
            RemovePharmaandStandardLinesFromOrderLinesFromOrder(recEmbro);
            RemoveLinesOfOrgSO(recShoify, 'Std&Emb');

            ReleaseSalesDoc.ReleaseSalesHeader(recEmbro, false);
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;

        //Order contains pharma & embroidered item
        if (pharmaCount >= 1) and (embroCount >= 1) and (standardCount <= 0) and (itemCount <> pharmaCount) and (itemCount <> embroCount) then begin

            recEmbro := createNewSalesOrder(recShoify."No.");
            RemoveLinesOfOrgSO(recShoify, 'Pha&Emb');
            RemovePharmaandStandardLinesFromOrderLinesFromOrder(recEmbro);

            ReleaseSalesDoc.ReleaseSalesHeader(recEmbro, false);
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;

        //Order contains standard & pharma & embroidered items
        if (standardCount >= 1) and (itemCount <> embroCount) and (itemCount <> pharmaCount) and (pharmaCount >= 1) and (embroCount >= 1) and (standardCount <> itemCount) then begin
            recEmbro := createNewSalesOrder(recShoify."No.");
            recPharma := createNewSalesOrder(recShoify."No.");

            RemovePharmaandStandardLinesFromOrderLinesFromOrder(recEmbro);
            RemoveEmbroideryandStandardLinesFromOrder(recPharma);
            RemoveLinesOfOrgSO(recShoify, 'Std&Pha&Emb');

            ReleaseSalesDoc.ReleaseSalesHeader(recEmbro, false);
            ReleaseSalesDoc.ReleaseSalesHeader(recPharma, false);
            ReleaseSalesDoc.ReleaseSalesHeader(recShoify, false);
            exit
        end;
    end;

    procedure RemoveLinesOfOrgSO(recSalesHeader: Record "Sales Header"; OrderType: Text)
    var
        rec_SalesLines: Record "Sales Line";
        recItem: Record Item;
        enumSalesItem: Enum "Sales Line Type";
        price: Decimal;
        Personalisation: Text;
    begin

        if (OrderType = 'Standard') or (OrderType = 'Pharma') or (OrderType = 'Embroidered') then begin
            Clear(price);
            //Add Carriage line 
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");

            if rec_SalesLines.FindFirst() then begin

                price := rec_SalesLines."Unit Price";

                rec_SalesLines.Init();
                rec_SalesLines."Document No." := recSalesHeader."No.";
                rec_SalesLines."Line No." := findLastSalesLinesNo(rec_SalesLines, recSalesHeader."No.");
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Type := "Sales Line Type"::Item;
                rec_SalesLines."No." := 'CARRIAGE';
                rec_SalesLines.Validate("No.");
                rec_SalesLines.Quantity := 1;
                rec_SalesLines.Validate(Quantity);
                rec_SalesLines."Unit Price" := price;
                rec_SalesLines.Validate("Unit Price");
                rec_SalesLines.Insert(true);
                Commit();
            end;

            //Delete GL account
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");
            if rec_SalesLines.FindFirst() then begin
                rec_SalesLines.Delete();
            end;

        end;

        if (OrderType = 'Std&Emb') then begin
            Clear(price);
            //Add Carriage line 
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");

            if rec_SalesLines.FindFirst() then begin

                price := rec_SalesLines."Unit Price";

                rec_SalesLines.Init();
                rec_SalesLines."Document No." := recSalesHeader."No.";
                rec_SalesLines."Line No." := findLastSalesLinesNo(rec_SalesLines, recSalesHeader."No.");
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Type := "Sales Line Type"::Item;
                rec_SalesLines."No." := 'CARRIAGE';
                rec_SalesLines.Validate("No.");
                rec_SalesLines.Quantity := 1;
                rec_SalesLines.Validate(Quantity);
                rec_SalesLines."Unit Price" := price;
                rec_SalesLines.Validate("Unit Price");
                rec_SalesLines.Insert(true);
                Commit();
            end;

            //Delete GL account
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");
            if rec_SalesLines.FindFirst() then begin
                rec_SalesLines.Delete();
            end;

            //Delete Embroidery lines
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            if rec_SalesLines.FindSet() then begin
                repeat
                    Clear(Personalisation);

                    Personalisation := rec_SalesLines.Personalisation.ToUpper();

                    if Personalisation = 'EMBROIDERY' then begin
                        rec_SalesLines.Delete();
                    end;

                until rec_SalesLines.Next() = 0;
            end;

        end;

        if (OrderType = 'Pha&Emb') then begin
            Clear(price);
            //Add Carriage line 
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");

            if rec_SalesLines.FindFirst() then begin
                price := rec_SalesLines."Unit Price";
                rec_SalesLines.Init();
                rec_SalesLines."Document No." := recSalesHeader."No.";
                rec_SalesLines."Line No." := findLastSalesLinesNo(rec_SalesLines, recSalesHeader."No.");
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Type := "Sales Line Type"::Item;
                rec_SalesLines."No." := 'CARRIAGE';
                rec_SalesLines.Validate("No.");
                rec_SalesLines.Quantity := 1;
                rec_SalesLines.Validate(Quantity);
                rec_SalesLines."Unit Price" := price;
                rec_SalesLines.Validate("Unit Price");
                rec_SalesLines.Insert(true);
                Commit();
            end;

            //Delete GL account
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");
            if rec_SalesLines.FindFirst() then begin
                rec_SalesLines.Delete();
            end;

            //Delete Embroidery lines
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            if rec_SalesLines.FindSet() then begin
                repeat
                    Clear(Personalisation);

                    Personalisation := rec_SalesLines.Personalisation.ToUpper();

                    if Personalisation = 'EMBROIDERY' then begin
                        rec_SalesLines.Delete();
                    end;

                until rec_SalesLines.Next() = 0;
            end;
        end;

        if (OrderType = 'Std&Pharma') then begin
            Clear(price);
            //Add Carriage line 
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");

            if rec_SalesLines.FindFirst() then begin
                price := rec_SalesLines."Unit Price";
                rec_SalesLines.Init();
                rec_SalesLines."Document No." := recSalesHeader."No.";
                rec_SalesLines."Line No." := findLastSalesLinesNo(rec_SalesLines, recSalesHeader."No.");
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Type := "Sales Line Type"::Item;
                rec_SalesLines."No." := 'CARRIAGE';
                rec_SalesLines.Validate("No.");
                rec_SalesLines.Quantity := 1;
                rec_SalesLines.Validate(Quantity);
                rec_SalesLines."Unit Price" := price;
                rec_SalesLines.Validate("Unit Price");
                rec_SalesLines.Insert(true);
                Commit();
            end;

            //Delete GL account
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");
            if rec_SalesLines.FindFirst() then begin
                rec_SalesLines.Delete();
            end;

            //Delete Pharma lines
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            if rec_SalesLines.FindSet() then begin
                repeat

                    recItem.Reset();
                    recItem.SetRange("No.", rec_SalesLines."No.");
                    recItem.SetRange(enhPharma, true);

                    if recItem.FindFirst() then begin
                        rec_SalesLines.Delete();
                    end;


                until rec_SalesLines.Next() = 0;
            end;
        end;

        if (OrderType = 'Std&Pha&Emb') then begin
            Clear(price);
            //Add Carriage line 
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");

            if rec_SalesLines.FindFirst() then begin
                price := rec_SalesLines."Unit Price";

                rec_SalesLines.Init();
                rec_SalesLines."Document No." := recSalesHeader."No.";
                rec_SalesLines."Line No." := findLastSalesLinesNo(rec_SalesLines, recSalesHeader."No.");
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Type := "Sales Line Type"::Item;
                rec_SalesLines."No." := 'CARRIAGE';
                rec_SalesLines.Validate("No.");
                rec_SalesLines.Quantity := 1;
                rec_SalesLines.Validate(Quantity);
                rec_SalesLines."Unit Price" := price;
                rec_SalesLines.Validate("Unit Price");
                rec_SalesLines.Insert(true);
                Commit();
            end;

            //Delete GL account
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            rec_SalesLines.SetRange(Type, enumSalesItem::"G/L Account");
            if rec_SalesLines.FindFirst() then begin
                rec_SalesLines.Delete();
            end;

            //Delete Pharma and Embroidery lines
            rec_SalesLines.Reset();
            rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
            rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
            if rec_SalesLines.FindSet() then begin
                repeat
                    Clear(Personalisation);

                    Personalisation := rec_SalesLines.Personalisation.ToUpper();

                    if Personalisation = 'EMBROIDERY' then begin
                        rec_SalesLines.Delete();
                    end;

                    recItem.Reset();
                    recItem.SetRange("No.", rec_SalesLines."No.");
                    recItem.SetRange(enhPharma, true);

                    if recItem.FindFirst() then begin
                        rec_SalesLines.Delete();
                    end;

                until rec_SalesLines.Next() = 0;
            end;
        end;

    end;

    procedure createNewSalesOrder(recShoifyNo: Code[50]): Record "Sales Header"
    var
        cu_CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ToSalesHeader: Record "Sales Header";
    begin
        ToSalesHeader.Init();
        ToSalesHeader.InitRecord;
        ToSalesHeader."Document Type" := enum_DocumentType::Order;
        ToSalesHeader.Insert(true);

        ToSalesHeader.SetRange("Document Type", enum_DocumentType::Order);
        ToSalesHeader.SetRange("No.", ToSalesHeader."No.");

        if ToSalesHeader.FindFirst() then begin
            cu_CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
            cu_CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, recShoifyNo, ToSalesHeader);
            // PAGE.Run(PAGE::"Sales Order", ToSalesHeader);
        end;
        exit(ToSalesHeader);
    end;

    procedure RemovePharmaandStandardLinesFromOrderLinesFromOrder(recSalesHeader: Record "Sales Header")
    var
        rec_SalesLines: Record "Sales Line";
        recItem: Record Item;
        isEmbro, isPharma : Boolean;
        Personalisation, No : Text;
    begin
        rec_SalesLines.Reset();
        rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
        rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
        if rec_SalesLines.FindSet() then begin
            repeat
                Clear(Personalisation);
                Personalisation := rec_SalesLines.Personalisation.ToUpper();

                if Personalisation <> 'EMBROIDERY' then begin
                    rec_SalesLines.Delete();
                end;
            until rec_SalesLines.Next() = 0;
        end;
        AddCarriageLine(recSalesHeader);
    end;

    procedure RemoveEmbroideryandStandardLinesFromOrder(recSalesHeader: Record "Sales Header")
    var
        isPharma: Boolean;
    begin
        rec_SalesLines.Reset();
        rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
        rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");
        if rec_SalesLines.FindSet() then begin
            repeat
                recItem.Reset();
                recItem.SetRange("No.", rec_SalesLines."No.");
                recItem.SetRange(enhPharma, true);

                if Not recItem.FindFirst() then begin
                    rec_SalesLines.Delete();
                end
            until rec_SalesLines.Next() = 0;
        end;
        AddCarriageLine(recSalesHeader);
    end;

    procedure AddCarriageLine(recSalesHeader: Record "Sales Header")
    var
        recItem: Record Item;
    begin
        rec_SalesLines.Reset();
        rec_SalesLines.SetRange("Document Type", enum_DocumentType::Order);
        rec_SalesLines.SetRange("Document No.", recSalesHeader."No.");

        if rec_SalesLines.FindSet() then begin

            recItem.Reset();
            recItem.SetRange("No.", 'CARRIAGE');
            if recItem.FindFirst() then begin
                rec_SalesLines.Init();
                rec_SalesLines."Line No." := findLastSalesLinesNo(rec_SalesLines, recSalesHeader."No.");
                rec_SalesLines."Document No." := recSalesHeader."No.";
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Type := "Sales Line Type"::Item;
                rec_SalesLines."No." := recItem."No.";
                rec_SalesLines.Validate("No.");
                rec_SalesLines."Document Type" := "Sales Document Type"::Order;
                rec_SalesLines.Quantity := 1;
                rec_SalesLines.Validate(Quantity);
                rec_SalesLines."Unit Price" := 0;
                rec_SalesLines.Validate("Unit Price");
                rec_SalesLines.Insert(true);
                Commit();
            end;

        end;
    end;

    procedure findLastSalesLinesNo(recSalesLines: Record "Sales Line"; SalesOrderNo: Code[50]): Integer
    var
        lastLineNo: Integer;
        recSalesHeader: Record "Sales Header";
    begin
        recSalesLines.SetRange("Document No.", SalesOrderNo);
        recSalesLines.SetCurrentKey("Line No.");
        rec_SalesLines.SetAscending("Line No.", false);
        if recSalesLines.FindFirst() then begin
            lastLineNo := recSalesLines."Line No." + 1000;
            exit(lastLineNo);
        end else begin
            lastLineNo := 1000;
            exit(lastLineNo);
        end;
    end;

    //Event to split the Order
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterProcessSalesDocument', '', false, false)]
    procedure OnAfterProcessSalesDocument(var SalesHeader: Record "Sales Header"; OrderHeader: Record "Shpfy Order Header")
    begin
        checkSalesLines(SalesHeader);
    end;
}
