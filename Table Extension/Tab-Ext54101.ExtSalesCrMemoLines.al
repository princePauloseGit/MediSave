tableextension 54101 "Ext Sales Cr.Memo Lines" extends "Sales Cr.Memo Line"
{
    fields
    {
        field(54100; "Ship-to Country/Region Code"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Ship-to Country/Region Code" where("No." = field("Document No.")));
        }
        field(54101; "Bill-To City"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Bill-to City" where("No." = field("Document No.")));
        }
        field(54102; "Bill-to County"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Bill-to County" where("No." = field("Document No.")));
        }
        field(54103; "Bill-to Postcode"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Bill-to Post Code" where("No." = field("Document No.")));
        }
        field(54104; "Ship-To City"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Ship-To City" where("No." = field("Document No.")));
        }
        field(54105; "Ship-to Postcode"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Ship-to Post Code" where("No." = field("Document No.")));
        }
        field(54106; "Ship-to State"; Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Header"."Ship-to County" where("No." = field("Document No.")));
        }
        field(45107; "Sell-to Customer Name"; Text[100])
        {
            CalcFormula = max(Customer.Name where("No." = field("Sell-to Customer No.")));
            FieldClass = FlowField;
        }
    }
}