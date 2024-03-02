tableextension 54104 ExtCustomer extends Customer
{
    fields
    {
        field(54100; "GMC Checked"; Date)
        {
            Caption = 'GMC Checked';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                cuGmcCheck: Codeunit GMCDateCheck;
            begin
                cuGmcCheck.updateGMCExpiry(Rec);
            end;

        }
    }
}
