namespace ERP_API.Models
{
    public class OrderCycles
    {
        public string? Cycle { get; set; }

        public List<CycleParts>? Part { get; set; }
    }

    public class CycleParts
    {
        public string? ID { get; set; }

        public string? Material { get; set; }

        public string? ZH { get; set; }

        public string? EN { get; set; }

        public string? VI { get; set; }

        public int TargetPairs { get; set; }

        public int DispatchedPairs { get; set; }

        public int ScanPairs { get; set; }

        public string? CuttingType { get; set; }
    }
}