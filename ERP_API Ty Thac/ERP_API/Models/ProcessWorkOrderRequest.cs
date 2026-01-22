namespace ERP_API.Models
{
    public class ProcessWorkOrderRequest
    {
        public string? Order { get; set; }

        public string? UserID { get; set; }

        public string? Department { get; set; }

        public string? Factory { get; set; }

        public string? Section { get; set; }

        public string? Type { get; set; }

        public List<List<string>>? Cycle { get; set; }

        public List<string>? Size { get; set; }
    }
}
