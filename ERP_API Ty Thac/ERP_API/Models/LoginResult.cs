namespace ERP_API.Models
{
    public class LoginResult
    {
        public Boolean Result { get; set; }

        public string? Status { get; set; }

        public string? UserID { get; set; }

        public string? UserName { get; set; }

        public string? Group { get; set; }

        public string? Department { get; set; }

        public string? Factory { get; set; }
    }
}
