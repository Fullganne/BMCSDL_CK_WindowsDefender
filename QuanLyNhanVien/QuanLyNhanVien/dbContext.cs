using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace QuanLyNhanVien
{
    public class dbContext
    {
        private SqlConnection connection;
        private string connectionString;

        public dbContext() { }

        public void SetConnectionString(string username, string password)
        {
            // Cập nhật chuỗi kết nối với serverName và databaseName tương ứng
            connectionString = $"Data Source=.\\SQLEXPRESS;Initial Catalog=QLNV1;User ID={username};Password={password}";
        }

        public SqlConnection GetConnection()
        {
            connection = new SqlConnection(connectionString);
            return connection;
        }

        public bool IsConnectionOpen()
        {
            return connection != null && connection.State == System.Data.ConnectionState.Open;
        }

        public void CloseConnection()
        {
            if (IsConnectionOpen())
            {
                connection.Close();
            }
        }

        public List<string> GetRoles()
        {
            List<string> roles = new List<string>();

            string query = @"
                SELECT name AS RoleName
                FROM sys.database_principals
                WHERE type = 'R' AND is_fixed_role = 0";

            try
            {
                using (SqlConnection connection = GetConnection())
                {
                    connection.Open();

                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        SqlDataReader reader = command.ExecuteReader();
                        while (reader.Read())
                        {
                            roles.Add(reader["RoleName"].ToString());
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
            }

            return roles;
        }
    }
}
