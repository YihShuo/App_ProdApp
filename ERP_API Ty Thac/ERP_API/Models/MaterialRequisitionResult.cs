namespace ERP_API.Models
{
    public class LeanList
    {
        public string? Lean { get; set; }

        public List<TimeSlot>? TimeSlots { get; set; }
    }

    public class TimeSlot
    {
        public string? Time { get; set; }

        public List<Section>? Section { get; set; }
    }

    public class Section
    {
        public string? ID { get; set; }

        public List<MRCard>? MRCard { get; set; }
    }

    public class MRCard
    {
        public string? ListNo { get; set; }

        public List<MRCardInfo>? MRCardInfo { get; set; }

        public string? Source { get; set; }

        public string? Remark { get; set; }

        public string? ConfirmDate { get; set; }

        public string? DeliveryCFMDate { get; set; }

        public string? ReceiverConfirmDate { get; set; }
    }

    public class MRCardInfo
    {
        public string? RY_Begin { get; set; }

        public string? RY_End { get; set; }

        public string? SKU { get; set; } 

        public string? BUY { get; set; }

        public string? Date { get; set; }

        public List<Material>? Materials { get; set; }
    }

    public class Material
    {
        public string? ID { get; set; }

        public double Usage { get; set; }

        public bool Confirmed { get; set; }

        public double IssuanceUsage { get; set; }

        public string? Unit { get; set; }

        public string? Remark { get; set; }
    }

    public class SKUGroup
    {
        public string? XieXing { get; set; }

        public string? SheHao { get; set; }

        public string? SKU { get; set; }

        public string? BuyNo { get; set; }

        public string? RY { get; set; }

        public string? RY_Begin { get; set; }

        public string? RY_End { get; set; }

        public string? Date { get; set; }
    }

    public class RYList
    {
        public string? RY_Begin { get; set; }

        public string? RY_End { get; set; }

        public string? Date { get; set; }

        public string? Section { get; set; }

        public string? Source { get; set; }

        public List<RYMaterials>? RYMaterial { get; set; }
    }

    public class RYMaterials
    {
        public string? MaterialID { get; set; }

        public double Qty { get; set; }

        public double ReqQty { get; set; }

        public string? Unit { get; set; }

        public string? Remark { get; set; }
    }
}