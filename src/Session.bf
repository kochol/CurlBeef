using System;
using System.Collections;

namespace curl
{
	public typealias URL = String;

	public class Session
	{
		public enum Verbs
		{
			Get,
			Post,
			Put
		}

		Easy easy = new Easy() ~ delete _;
		Easy.curl_slist* headers = null ~ Easy.curl_slist_free_all(_);
		String error_buf = new String(256) ~ delete _;
		public URL Url = null;
		public int64 ResponseCode = 0;
		String body = new String() ~ delete _;

		uint8* file_data;
		int32 file_size;
		int32 file_read;

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

			let r = easy.Perform();

			if (r == .Ok)
				ResponseCode = easy.GetInfoLong(.ResponseCode);

			return r;
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

		public void SetVerb(Verbs verb)
		{
			switch (verb)
			{
			case .Get:
				easy.SetOpt(.HTTPGet, true);
			case .Post:
				easy.SetOpt(.Customrequest, "POST");
			case .Put:
				easy.SetOpt(.Put, true);
			}
		}

		static int read_callback(void* dataPtr, int size, int count, void* ctx)
		{
			Session s = (Session)Internal.UnsafeCastToObject(ctx);

			int read = s.file_size - s.file_read;
			if (read == 0)
				return 0;
			if (read > size * count)
				read = size * count;

			Internal.MemCpy(dataPtr, s.file_data, read);
			Console.WriteLine("DEBUG: Read {} bytes", read);
			return read;
		}

		public void AddFileToUpload(uint8* data, int32 size)
		{
			file_data = data;
			file_size = size;
			file_read = 0;

			if (data == null)
			{
				// reset upload data
				easy.SetOptFunc(.ReadFunction, null);

				/* enable uploading */ 
				easy.SetOpt(.Upload, false);

				/* now specify which file to upload */ 
				easy.SetOpt(.ReadData, (void*)null);

				/* provide the size of the upload, we specicially typecast the value
				   to curl_off_t since we must be sure to use the correct data size */ 
				easy.SetOpt(.InfileSize, 0);
			}
			else
			{
				// set the file

				/* we want to use our own read function */
				function int(void* ptr, int size, int count, void* stream) readFunc = => read_callback;
				easy.SetOptFunc(.ReadFunction, (void*)readFunc);

				/* enable uploading */ 
				easy.SetOpt(.Upload, true);

				/* now specify which file to upload */ 
				easy.SetOpt(.ReadData, Internal.UnsafeCastToPtr(this));

				/* provide the size of the upload, we specicially typecast the value
				   to curl_off_t since we must be sure to use the correct data size */ 
				easy.SetOpt(.InfileSize, size);
			}
		}

		public void SetRequestBody(String _body)
		{
			easy.SetOpt(.Postfields, _body);
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
