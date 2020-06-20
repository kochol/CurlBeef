using System;

namespace curl
{
	public typealias URL = String;

	public class Session
	{
		Easy easy = new Easy() ~ delete _;
		String error_buf = new String(256) ~ delete _;
		public URL Url = null ~ delete _;
		String body = new String() ~ delete _;

		/** Constructor
		* Set up some defaults
		*/
		public this()
		{
			easy.SetOpt(.FollowLocation, true);
			easy.SetOpt(.NoProgress, true);
			easy.SetOpt(.MaxRedirs, 50);
			easy.SetOpt(.ErrorBuffer, error_buf.Ptr);
			easy.SetOpt(.CookieFile, "");
			easy.SetOpt(.TCPKeepalive, true);
		}

		/** Write call back for curl
		*/
		static int Write(void* dataPtr, int size, int count, void* ctx)
		{
			Session s = (Session)Internal.UnsafeCastToObject(ctx);
			s.body.Append((char8*)dataPtr, size * count);
			return count;
		}

		/** Create request and send it
		*/
		void makeRequest()
		{
			String url = scope String(Url);
			url.Replace(" ", "%20");
			url.Replace("%", "%25");
			url.Replace("\"", "%22");
			url.Replace("<", "%3C");
			url.Replace(">", "%3E");

			url.Replace("(", "%28");
			url.Replace(")", "%29");
			url.Replace("[", "%5B");
			url.Replace("]", "%5D");
			url.Replace("\\", "%5C");
			url.Replace("^", "%5E");

			url.Replace("`", "%60");
			url.Replace("{", "%7B");
			url.Replace("}", "%7D");
			url.Replace("|", "%7C");

			easy.SetOpt(.URL, url);
			easy.SetOpt(.AcceptEncoding, "");

			error_buf.Set("");
			body.Clear();

			function int(void* ptr, int size, int count, void* ctx) writeFunc = => Write;
			easy.SetOptFunc(.WriteFunction, (void*)writeFunc);
			easy.SetOpt(.WriteData, Internal.UnsafeCastToPtr(this));

			easy.Perform();
		}

		/** Returns the site data as string
		*/
		public String GetString()
		{
			makeRequest();
			return body;
		}
	}
}
