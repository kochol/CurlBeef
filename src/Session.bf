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
			s.body.Clear();
			s.body.Append((char8*)dataPtr, size * count);
			return count;
		}

		/** Create request and send it
		*/
		void makeRequest()
		{
			easy.SetOpt(.URL, Url);
			easy.SetOpt(.AcceptEncoding, "");

			error_buf.Set("");

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
