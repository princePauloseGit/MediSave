pageextension 54102 ItemCardPage extends "Item Card"
{
    actions
    {
        addfirst(processing)
        {
            action(FullItemUpdate)
            {
                Caption = 'Surgery Network Stock Level Update';
                ApplicationArea = All;
                Promoted = true;
                Image = Process;
                trigger OnAction();
                var
                    cuSNProductLeveUpdate: Codeunit SNProductLeveUpdate;
                begin
                    cuSNProductLeveUpdate.SNProductAPIConnect(Rec."No.", '');
                end;
            }
        }
    }
}
