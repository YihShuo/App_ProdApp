namespace ERP_API.Models
{
    public class OrderRequest
    {
        public string? Order { get; set; }

        public string? PartID { get; set; }

        public string? MachineType { get; set; }

        public string? Machine { get; set; }

        public bool NeedProcess { get; set; }

        public string? Section { get; set; }

        public string? Type { get; set; }
    }

    public class ProcessRequest
    {
        public string? Order { get; set; }

        public string? Section { get; set; }
    }
}
