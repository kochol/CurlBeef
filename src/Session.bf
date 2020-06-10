using System;

namespace curl
{
	public typealias URL = String;

	public class Session
	{
		Easy easy = new Easy() ~ delete _;
		String error_buf = new String(256) ~ delete _;
		public URL Url = null ~ delete _;

		/** Constructor
		* Set up some defaults
		*/
		public this()
		{
			easy.SetOpt(.FollowLocation, true).ReturnValueDiscarded();
			easy.SetOpt(.NoProgress, true).ReturnValueDiscarded();
			easy.SetOpt(.MaxRedirs, 50).ReturnValueDiscarded();
			easy.SetOpt(.ErrorBuffer, error_buf.Ptr).ReturnValueDiscarded();
			easy.SetOpt(.CookieFile, "").ReturnValueDiscarded();
			easy.SetOpt(.TCPKeepalive, true).ReturnValueDiscarded();
		}

		static int Write(void* dataPtr, int size, int count, void* ctx)
		{

			return count;
		}


		void makeRequest()
		{
			easy.SetOpt(.URL, Url);
			easy.SetOpt(.AcceptEncoding, "");

			error_buf[0] = 0;

			function int(void* ptr, int size, int count, void* ctx) writeFunc = => Write;
			easy.SetOptFunc(.WriteFunction, (void*)writeFunc);
			easy.SetOpt(.WriteData, Internal.UnsafeCastToPtr(this));
		}
	}
}
