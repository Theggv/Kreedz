/*
  *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * See LICENSE.TXT file for more information.
 *
 */
 #if defined _AmxxArch_included
	#endinput
#endif
#define _AmxxArch_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib AmxxArch
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib AmxxArch
	#endif
#else
	#pragma library AmxxArch
#endif

#define AA_NO_ERROR		0

/*
*	@param filepath		Path to the file		
*	@param outdir		Directory where the archive will be unpacked
*	@param callback		Callback function (example: public OnComplete(idcaller, error))
*	@param idcaller		player id or 0
*
*	@noreturn
*/
native AA_Unarchive( const filepath[], const outdir[], const callback[], const idcaller = 0);