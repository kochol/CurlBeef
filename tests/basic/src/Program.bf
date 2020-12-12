using curl;
using System;

namespace basic
{
	class Program
	{
		static void Main()
		{
			Session se = scope Session();
			se.Url = scope String("http://ip.jsontest.com/");
			Console.WriteLine(se.GetString());
			Console.Read();
		}
	}
}
