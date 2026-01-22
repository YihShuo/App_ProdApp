var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

var mySpecificOrigins = "_mySpecificOriginsPolicy";
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: mySpecificOrigins, policy =>
    {
        policy
        .WithOrigins("http://prodapp.tythac.com.vn:8080")
        .WithMethods("GET", "POST")
        .WithHeaders("Content-Type", "Authorization");
    });
});

builder.Services.AddHttpClient();
builder.Services.AddControllers();

var app = builder.Build();

// Configure the HTTP request pipeline.

app.UseHttpsRedirection();

app.UseCors(mySpecificOrigins);

app.UseAuthorization();

app.MapControllers();

app.Run();