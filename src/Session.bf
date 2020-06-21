using System;
using System.Collections;

namespace curl
{
	public typealias URL = String;

	public class Session
	{
		Easy easy = new Easy() ~ delete _;
		Easy.curl_slist* headers = null ~ Easy.curl_slist_free_all(_);
		String error_buf = new String(256) ~ delete _;
		public URL Url = null;
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
		Result<void, Easy.ReturnCode> makeRequest()
		{
			String url = scope String(Url);
			url.Replace("%", "%25");
			url.Replace(" ", "%20");
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

			return easy.Perform();
		}

		public Result<void, Easy.ReturnCode> SetHeaders(List<String> _headers)
		{
			if (headers != null)
			{
				Easy.curl_slist_free_all(headers);
				headers = null;
			}
			if (_headers != null)
				for (var s in _headers)
					headers = Easy.curl_slist_append(headers, s);
			return easy.SetOpt(.HTTPHeader, headers);
		}

		/** Returns the site data as string
		*/
		public Result<String, Easy.ReturnCode> GetString()
		{
			let r = makeRequest();
			switch (r)
			{
			case .Err(let err):
				return .Err(err);
			case .Ok:
				return .Ok(body);
			}
		}
	}
}
