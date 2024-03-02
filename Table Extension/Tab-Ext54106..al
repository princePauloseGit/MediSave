tableextension 54106 "Item Table Extension" extends Item
{
    fields
    {
        modify(Blocked)
        {
            trigger OnAfterValidate()
            var
                cuSNProductLeveUpdate: Codeunit SNProductLeveUpdate;
                block: Code[50];
            begin
                Description := Description.ToLower();
                if (Blocked = true) or (Description.Contains('discont'))
                then begin
                    block := 'YES';
                end;
                cuSNProductLeveUpdate.SNProductAPIConnect(Rec."No.", block);
            end;
        }
        modify(Description)
        {
            trigger OnAfterValidate()
            var
                cuSNProductLeveUpdate: Codeunit SNProductLeveUpdate;
                discont: Code[50];
            begin
                Description := Description.ToLower();
                if Description.Contains('discont') or (Blocked = true) then begin
                    discont := 'YES';
                end;
                cuSNProductLeveUpdate.SNProductAPIConnect(Rec."No.", discont);
            end;
        }
    }
}
