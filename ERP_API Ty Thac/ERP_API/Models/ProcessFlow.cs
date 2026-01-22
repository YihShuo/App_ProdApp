namespace ERP_API.Models
{
    public class ProcessFlow
    {
        public string? Section { get; set; }

        public int Target { get; set; }

        public int Actual { get; set; }
        
        public string? ZH { get; set; }

        public string? EN { get; set; }

        public string? VI { get; set; }

        public string? Parent { get; set; }

        public int Status { get; set; }
    }
}
